<?php
$home_dir = '/home/ethos/';
$gruve_dir = $home_dir . '.gruve/';

$db = json_decode(file_get_contents($gruve_dir . 'db.json'));

$since = (!empty($_GET['since']) ? $_GET['since'] : 0);
$metric = (!empty($_GET['metric']) ? $_GET['metric'] : 0);

$output = new \stdClass();
$output->stats = [];

$hashrate_data = new \stdClass();
$hashrate_data->result = [];

for ($i = 0; $i < count($db->stats); $i++) {
    if ($db->stats[$i]->timestamp > $since) {
        array_push($output->stats, $db->stats[$i]);
        $hashrate_row = new \stdClass();
        $hashrate_row->value = [];
        $hashrate_row->timeframe = new \stdClass();
        $hashrate_row->timeframe->start = date('c', $db->stats[$i]->timestamp);
        $hashrate_row->timeframe->end = date('c', $db->stats[$i]->timestamp);

        $gpus = explode(' ', $db->stats[$i]->data->$metric);
        for($j = 0; $j < count($gpus); $j++) {
            $gpu = new \stdClass();
            $gpu->gpu = 'GPU #' . $j;
            $gpu->result = $gpus[$j];
            array_push($hashrate_row->value, $gpu);
        }

        array_push($hashrate_data->result, $hashrate_row);
    }
}

$hashrate_rows = $hashrate_data->result;
$hashrate_reduced = [];

$total_points = count($hashrate_rows);
if ($total_points > 100) {
    $jump = $total_points / 100;
    $jump = floor($jump);
    if ($jump >= 1) {
        for ($i = 0; $i < $total_points; $i++) {
            if ($i % $jump == 0) {
                array_push($hashrate_reduced, $hashrate_rows[$i]);
            }
        }
    }
}

$hashrate_data->result = $hashrate_reduced;

echo json_encode($hashrate_data);
