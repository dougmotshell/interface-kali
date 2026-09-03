panelIds.forEach(panelId => {
    const panel = panelById(panelId);
    panel.widgetIds.forEach(widgetId => {
        const widget = panel.widgetById(widgetId);
        if (widget.type === 'org.kde.plasma.icontasks') {
            widget.currentConfigGroup = ["General"];
            widget.writeConfig('launchers', ['applications:org.kde.dolphin.desktop', 'applications:org.kde.kate.desktop', 'applications:firefox-esr.desktop', 'applications:org.kde.konsole.desktop']);
        }
        if (widget.type === 'org.kde.plasma.kickoff') {
            widget.currentConfigGroup = ["General"];
            widget.writeConfig('icon', 'kali-panel-menu-large');
        }
    });
});
