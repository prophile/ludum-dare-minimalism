<?php

$contents = scandir('contents');

header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');

function sendMessage($event, $contents)
{
    $message = "event: $event\r\n";
    $body = "data: " . json_encode($contents) . "\r\n\r\n";
    echo $message . $body;
}

class Item {
    private $name;
    private $path;
    private $lastChanged = 0;

    public function __construct($name)
    {
        $this->name = $name;
        $this->path = "contents/$name";
    }

    public function transmitIfChanged()
    {
        $modTime = filemtime($this->path);
        if ($modTime > $this->lastChanged) {
            $this->lastChanged = $modTime;
            $contents = file_get_contents($this->path);
            $message = array('item' => $this->name,
                             'contents' => $contents);
            // retransmit
            sendMessage('file', $message);
        }
    }
}

$items = array();

foreach ($contents as $item) {
    if (empty($item) or $item[0] == '.')
        continue;
    $items[] = new Item($item);
}

while (true) {
    sendMessage('hello', 'bees');
    flush();

    clearstatcache();
    foreach ($items as $item) {
        $item->transmitIfChanged();
    }
    flush();
    sleep(6);
}

?>

