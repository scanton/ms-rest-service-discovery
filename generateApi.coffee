#coffee generateApi.coffee ./access.json LPAccessAPI
args = [];
argCount = 0;
process.argv.forEach (val, index, array) ->
	if argCount > 1
		args.push val.split "|"
	++argCount

if args && args[0] && args[0][0] && args[1][0]
	uri = args[0][0]

trace = console.log

getName = (methodData) ->
	verb = methodData.verb.toLowerCase()
	a = methodData.path.split('{')[0].split '/'
	l = a.length
	while l--
		if a[l] != ''
			return verb.toLowerCase() + a[l]
getAction = (str) ->
	if str.toLowerCase() == 'delete'
		return 'remove'
	return str.toLowerCase()
concatPath = (str) ->
	str.split("{").join("' . $").split("}").join(" . '")
getPhpParams = (params, verb) ->
	if !params
		return ''
	a = []
	for i of params
		a.push '$' + params[i].name
		++i
	if verb.toLowerCase() != 'get'
		a.push '$bodyParams'
	return a.join ", "
addParams = (str) ->
	if str.toLowerCase() != 'get'
		return ', $bodyParams'
	return ''

data = require uri
if data
	s = "<?php

require_once('RestConnector.php');

class " + args[1][0] + " extends RestConnector {
	
	public $serviceUri = '';
	public $testMode = false;
	
	public function __construct($testMode = false, $serviceUri) {
		$this->serviceUri = $serviceUri;
		$this->testMode = $testMode;
	}
"
	l = data.length
	while l--
		d = data[l]
		name = getName d
		#trace getAction(d.verb)
		if d.uriParameters
			s += ' public function ' + name + '(' + getPhpParams(d.uriParameters, d.verb) + addParams(d.verb) + ') { return $this->' + getAction(d.verb) + '("' + concatPath(d.path) + '"); }'
		else 
			s += ' public function ' + name + '() { return $this->' + getAction(d.verb) + '("' + d.path + '"' + addParams(d.verb) + '); }'

	trace s + '}'
