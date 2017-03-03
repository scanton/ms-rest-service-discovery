#coffee generateApi.coffee ./access.json LPAccessAPI

fs = require 'fs'

args = [];
argCount = 0;
process.argv.forEach (val, index, array) ->
	if argCount > 1
		args.push val.split "|"
	++argCount

if args && args[0] && args[0][0] && args[1][0]
	uri = args[0][0]

className = args[1][0]

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
	s = str.split("{").join("' . $").split("}").join " . '"
	l = s.length
	s.slice 0, l - 3
getPhpParams = (params, verb, body) ->
	if body
		bodyCount = body.length
	else
		bodyCount = 0
	if !params
		return ''
	a = []
	for i of params
		a.push '$' + params[i].name
		++i
	if verb.toLowerCase() != 'get' && bodyCount
		a.push '$bodyParams'
	return a.join ", "
addParams = (str, body) ->
	if str.toLowerCase() != 'get'
		if body
			return ', $bodyParams'
		else
			return ', array()'
	return ''
getUrlSessionParams = (params) ->
	result = ''
	if params
		l = params.length
		i = 0
		while i < l
			p = params[i]
			result += ' $' + p.name + " = $_GET['" + p.name + "'] ? " + "$_GET['" + p.name + "'] : $_SESSION['" + p.name + "']; \n\r"
			++i
	result
createAjaxCall = (method) ->
	if !instanceName
		instanceName = '$access'
	name = getName method
	result = "<?php header('Content-Type: application/json'); set_include_path('../../../'); include_once('common/ajax_bootstrap.php'); "
	result += getUrlSessionParams method.uriParameters
	if method.bodyParameters
		result += " $bodyParams = json_decode($_POST['details']); \n\r"
	result += ' $result = ' + instanceName + '->' + name + '(' + getPhpParams(method.uriParameters, method.verb, method.bodyParameters) + ');'
	result += ' echo json_encode($result); \n\r ?>'

	dir = './' + className + '/js/ajax/' + className + '/'
	fs.writeFile dir + name + '.php', result, (err) ->
		if err
			trace err
		else
			trace dir + name + '.php was saved'

data = require uri
if data && className
	s = "<?php

require_once('RestConnector.php');

class " + className + " extends RestConnector {
	
	public $serviceUri = '';
	public $testMode = false;
	
	public function __construct($testMode = false, $serviceUri) {
		$this->serviceUri = $serviceUri;
		$this->testMode = $testMode;
	}
"
	l = data.length
	i = 0
	while i < l
		d = data[i]
		createAjaxCall d
		name = getName d
		action = getAction d.verb
		params = addParams d.verb, d.bodyParameters
		if d.uriParameters
			phpParams = getPhpParams d.uriParameters, d.verb, d.bodyParameters
			path = concatPath d.path
			s += ' public function ' + name + '(' +  phpParams + ') { return $this->' + action + "('" + path + ' ' + params + '); }'
		else 
			if d.bodyParameters
				s += ' public function ' + name + '($bodyParams) { return $this->' + action + '(\'' + d.path + '\'' + params + '); }'
			else
				s += ' public function ' + name + '() { return $this->' + action + '(\'' + d.path + '\'' + params + '); }'
		++i
	api = s + '}'
	dir = './' + className + '/src/'
	#if !fs.existsSync dir
	#	fs.mkdirSync dir
	fs.writeFile dir + className + '.php', api, (err) ->
		if err
			trace err
		else
			trace dir + className + '.php was saved'
