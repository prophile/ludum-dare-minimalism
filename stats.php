<?php

$contents = json_decode($HTTP_RAW_POST_DATA);

$contents->client = $_SERVER['REMOTE_ADDR'];

$re_encode = json_encode($contents);

$fp = fopen('events.log', 'a');
fwrite($fp, "$re_encode\n");
fclose($fp);

