#coffee objectFactory.coffee ./access.json POST-api-v1-Validation-InsertExistingVerificationRequest-WebuserID-SecSessionID bodyParameters
args = [];
argCount = 0;
process.argv.forEach (val, index, array) ->
	if argCount > 1
		args.push val.split "|"
	++argCount

if args && args[0] && args[0][0]
	uri = args[0][0]

trace = console.log

getDefaultValue = (type) ->
	if type == 'integer'
		return 0
	else if type == 'boolean'
		return false
	else if type == 'globally unique identifier'
		return '00000000-0000-0000-0000-000000000000'
	else
		return ''

generateSampleObject = (data) ->
	o = {}
	l = data[0].length
	while l--
		o[data[0][l].name] = getDefaultValue data[0][l].type
	o

data = require uri
if data
	l = data.length
	while l--
		if data[l].id == args[1][0]
			trace generateSampleObject data[l][args[2][0]]
			break
