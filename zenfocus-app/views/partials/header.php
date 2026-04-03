<?php

declare(strict_types=1);

$config = app_config();
$pageTitle = $pageTitle ?? 'PulseFocus';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= escape_html($pageTitle) ?> | <?= escape_html($config['app']['company_name']) ?></title>
    <link rel="stylesheet" href="assets/css/main.css">
</head>
<body>
<header class="topbar">
    <a class="brand" href="index.php">
        <img src="assets/img/logo.svg" alt="<?= escape_html($config['app']['company_name']) ?> logo" class="brand-logo">
        <span class="brand-text">Pomofocus</span>
    </a>
    <nav class="topbar-actions" aria-label="Header actions">
        <a class="top-link" href="index.php">Setting</a>
        <span class="brand-domain"><?= escape_html($config['app']['company_name']) ?></span>
    </nav>
</header>
<main class="page">
