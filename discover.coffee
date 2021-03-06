args = [];
argCount = 0;
process.argv.forEach (val, index, array) ->
	if argCount > 1
		args.push val.split "|"
	++argCount

if args && args[0] && args[0][0]
	helpFile = args[0][0]

a = helpFile.split "http://"
s = a.pop()
a = s.split "/"
host = 'http://' + a[0]

request = require 'request'
cheerio = require 'cheerio'

trace = console.log

"""
String functions
"""

stripAndTrim = (str) ->
	str.split("\r").join("").split("\n").join("").trim()

camelCase = (str, isClass = false) ->
	delimiters = [' ', '-', '_']
	l = delimiters.length
	while l--
		str = str.split(delimiters[l]).join "*"
	a = str.toLowerCase().split "*"
	l = a.length
	while l--
		s = a[l]
		s = s.slice(0, 1).toUpperCase() + s.slice 1
		a[l] = s
	s = a.join ""
	if !isClass
		s = s.slice(0, 1).toLowerCase() + s.slice 1
	return s

"""
Make remote calls and parse result
"""

request helpFile, (err, resp, body) ->
	if err
		throw err
	$ = cheerio.load body
	
	"""
	Get Top Level Data Object
	"""
	getDots = (count) ->
		s = ''
		c = count
		while c--
			s += '.'
		return s + ' (' + count + ')'

	parseTable = ($table) ->
		a = []
		$table.find("tbody tr").each ->
			o = {}
			$(this).find("td").each ->
				$this = $ this
				label = $this.attr("class").split("parameter-")[1]
				value = stripAndTrim $this.text()
				o[label] = value
			a.push o
		a
	
	getDefaultParam = (type) ->
		if(type == 'integer')
			return 0
		else if(type == 'decimal number')
			return 0.0
		else if(type == 'boolean')
			return false
		else if(type == 'globally unique identifier')
			return '00000000-0000-0000-0000-000000000000'
		else
			return ''
			
	createSample = (arr) ->
		o = {}
		l = arr.length
		i = 0
		while i < l
			param = arr[i]
			o[param.name] = getDefaultParam param.type
			++i
		return o
		
	addSamples = (data) ->
		l = data.length
		i = 0
		while i < l
			item = data[i]
			if item.uriParameters
				item.uriSample = createSample item.uriParameters
			if item.bodyParameters
				item.bodySample = createSample item.bodyParameters
			if item.resourceDescription
				item.resourceSample = createSample item.resourceDescription
			++i
		return data
	
	createRootDataObject = ($elements) ->
		services = []
		topic = ''
		$elements.each ->
			$this = $ this
			if $this.is "h2"
				topic = $this.text()
			else
				$this.find("tbody tr").each ->
					$tr = $ this
					$apiName = $tr.find ".api-name"
					link = $apiName.find("a").attr "href"
					description = stripAndTrim $tr.find(".api-documentation").text()
					name = $apiName.text()
					id = link.split("/").pop()
					a = name.split " "
					services.push
						id: id
						topic: topic
						verb: a[0]
						path: a[1]
						description: description
						detailPage: link
		services
	
	r = createRootDataObject $(".main-content").children()
	totalMethods = l = r.length
	methodsFound = i = 0
	
	while i < l
		((i) ->
			method = r[i]
			request host + method.detailPage, (err, resp, body) ->
				subject = ''
				$detail = cheerio.load body
				$content = $detail ".main-content div"
				$content.children().each ->
					$this = $ this
					if $this.is "h3"
						subject = camelCase $(this).text()
					else if $this.is "table"
						#if !method[subject] then method[subject] = []
						method[subject] = parseTable $this
				++methodsFound
				if methodsFound == totalMethods
					trace JSON.stringify addSamples r
		)(i)
		i++
