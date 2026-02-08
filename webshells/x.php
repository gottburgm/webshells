<?php

/////////////////////////////////////////
//    Zone-H submitter BY AnonGhost
// ( with HTTP Pipelining support ) //
//          BY
//      Mauritania Attacker
/////////////////////////////////////////


/////////////////////////////////////////
// USAGE::
// Linux: php-cli zone.php domains.txt
// Windows : "[path to php]" zone.php domains.txt
// e.g: "C:\PHP\php.exe" zone.php domains.txt

//OR

// upload to a server,and the browse http://site.com/zone.php
/////////////////////////////////////////

$defacer='Your Nick';
$display_details=0;      // SET it to '1' to display domains as it is submitted
$team='AnonGhost';        

////////////////DO NOT EDIT ANYTHING BELOW//////////////////


error_reporting(0);
set_time_limit(0);
if(!function_exists('curl_init')){echo "cURL not installed/disabled.\n";exit;}
$cli=(isset($argv[0]))?1:0;
if($cli==1){
$file=$argv[1];
$sites=file($file);
if(!file_exists($file)){echo "$file not found.\n";exit;}
}else{

if(function_exists(apache_setenv)){
@apache_setenv('no-gzip', 1);}
@ini_set('zlib.output_compression', 0);
@ini_set('implicit_flush', 1); 
@ob_implicit_flush(true);
@ob_end_flush();

if(isset($_POST['domains'])){
$sites=explode("\n",$_POST['domains']);
}
if (file_exists($_FILES["file"]["tmp_name"])){
$file=$_FILES["file"]["tmp_name"];$sites=file($file);}
echo <<<EOF
<html>
<head>
<meta http-equiv="Content-Language" content="en-us">
</head>
<title>Fastest Zone-H Mass Deface Poster</title>
<body text="#00FF00" bgcolor="#000000" vlink="#008000" link="#008000" alink="#008000">
<div align="center">
<table width="67%" style="border: 2px dashed #FF0000; background-color: #000000; color:#C0C0C0">
<tr><td align=center>
 <font face="Courier New" size=4 color=yellow>Fastest Zone-H Mass Deface Poster</font>
</td></tr>
</table>
<br /><pre>
EOF;
if(!isset($_POST['defacer'])){
echo <<<EOF
<form enctype="multipart/form-data" method="POST">
<div align='center'>
<span lang='en-us'><font color='#FF0000'><b>Your Nick:</b></font></span><br/><input name="defacer" type="text" value="$defacer" /><br/>
<table width='55%' style='border: 2px dashed #FF0000; background-color: #000000; color:#C0C0C0'>
<tr>
<td align='center'>
<span lang='en-us'><font color='#FF0000'><b>Domains:</b></font></span>

<p align='center'>&nbsp;<textarea rows='30' name='domains' cols='50' style='border: 2px dashed #FFFFFF; background-color: #000000; color:#C0C0C0'></textarea><br/>
<span lang='en-us'><font color='#FF0000'><b>OR</b></font></span><br/>Submit form .txt file:<br/><input name="file" type="file" /><br /> <br/><br/><input type='submit' value='    Subtmit    ' name='submit' style='color: #FF0000; font-weight: bold; border: 1px dashed #333333; background-color: #000000'></p></td>
</tr>
</table></form>
EOF;
}
$defacer=$_POST['defacer'];}
if(!$sites){echo '</pre></body></html>';exit;}
$sites=array_unique(str_replace('http://','',$sites));
$total=count($sites);
echo "[+] Total unique domain: $total\n\n";

$pause=10;
$start=time();
$main=curl_multi_init();

for($m=0;$m<3;$m++){
$http[] = curl_init(); 
}
for($n=0;$n<$total;$n +=30){
if($display_details==1){
for($x=0;$x<30;$x++){
echo'[+] Adding '.rtrim($sites[$n+$x]).'';
echo "\n";
}
}
$d=$n+30;
if($d>$total){$d=$total;}
echo "=====================>[$d/$total]\n";

for($w=0;$w<3;$w++){
$p=$w * 10;

if(!(isset($sites[$n+$p]))){$pause=$w;break;}
$posts[$w]="hacker=$defacer&team=$team&url=http%3A%2F%2F".rtrim($sites[$n+$p])."&key=kucing&secret=tai";

$curlopt=array(CURLOPT_USERAGENT => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.16 (KHTML, like Gecko) Chrome/18.0.1003.1 Safari/535.16',CURLOPT_RETURNTRANSFER => true,CURLOPT_FOLLOWLOCATION =>true,CURLOPT_ENCODING => true,CURLOPT_HEADER => false,CURLOPT_HTTPHEADER => array("Keep-Alive: 7"),CURLOPT_CONNECTTIMEOUT => 3,CURLOPT_URL => 'http://ghost-mirror.org/notify_act.php',CURLOPT_POSTFIELDS => $posts[$w]);
curl_setopt_array($http[$w],$curlopt);
curl_multi_add_handle($main,$http[$w]);


}

$running = null; 
        do{ 
                curl_multi_exec($main,$running); 
        }while($running > 0); 
for($m=0;$m<3;$m++){
if($pause==$m){break;}
curl_multi_remove_handle($main, $http[$m]);
 $code = curl_getinfo($http[$m], CURLINFO_HTTP_CODE); 
 if ($code != 200) {
while(true){
 echo' [-]Serevr Error!....Retrying';echo "\n";
 sleep(5);
curl_exec($http[$m]);
 $code = curl_getinfo($http[$m], CURLINFO_HTTP_CODE); 
if( $code== 200){break 1;}

 } } } }
 
 $end= time() - $start;
echo '+++++++DONE+++++++';echo "\n\n[*]Time took: $end seconds\n";curl_multi_close($main);
if($cli==0){echo '</pre></body></html>';}
exit;
?>
