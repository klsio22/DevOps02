<?php

declare(strict_types=1);

$config = app_config();
$pageTitle = $pageTitle ?? 'Service Requests';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= escape_html($pageTitle) ?> | <?= escape_html($config['app']['company_name']) ?></title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
<header class="topbar">
    <a class="brand" href="index.php">
        <img src="assets/logo.svg" alt="OrbitVale Systems logo" class="brand-logo">
        <span class="brand-text"><?= escape_html($config['app']['company_name']) ?></span>
    </a>
    <p class="brand-domain"><?= escape_html($config['app']['domain']) ?></p>
</header>
<main class="page">
