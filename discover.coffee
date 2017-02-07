helpFile = '{serviceURI}'

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

	createRootDataObject = ($elements) ->
		o = {services: []}
		topic = ''
		$elements.each ->
			$this = $ this
			if $this.is("h2")
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
					o.services.push
						id: id
						topic: topic
						verb: a[0]
						path: a[1]
						description: description
						detailPage: link
		o
	
	r = createRootDataObject $(".main-content").children()
	l = r.services.length
	i = 0
	while i < l
		method = r.services[i]
		request host + method.detailPage, (err, resp, body) ->
			result = {}
			subject = ''
			$detail = cheerio.load body
			$content = $detail ".main-content div"
			$content.children().each ->
				$this = $ this
				if $this.is "h3"
					subject = camelCase $(this).text()
				else if $this.is "table"
					if !result[subject] then result[subject] = []
					result[subject].push parseTable $this
				trace JSON.stringify result
		i++
