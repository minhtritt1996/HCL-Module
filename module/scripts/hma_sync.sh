#!/system/bin/sh
# HyperOS Compatibility Layer - Hide My Applist (HMA) Configuration Harmonizer
# Executes at late boot in background or when triggered via WebUI.

HMA_CONFIG=$(ls -1 /data/misc/hide_my_applist_*/config.json 2>/dev/null | head -n 1)
[ -f "$HMA_CONFIG" ] || exit 0

echo "[*] Synchronizing HMA package isolation templates..."

# If python3 is available at runtime, use it safely
if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json, sys
cfg_path = '$HMA_CONFIG'
try:
    with open(cfg_path, 'r') as f:
        cfg = json.load(f)
    scope = cfg.setdefault('scope', {})
    for pkg in ['com.sacombank.ewallet', 'com.tpb.mb.gprsandroid']:
        p_cfg = scope.setdefault(pkg, {
            'useWhitelist': False,
            'excludeSystemApps': False,
            'hideInstallationSource': False,
            'hideSystemInstallationSource': False,
            'excludeTargetInstallationSource': False,
            'invertActivityLaunchProtection': False,
            'excludeVoldIsolation': False,
            'restrictedZygotePermissions': [],
            'applyTemplates': ['HIDE MY CUSTOM APP'],
            'applyPresets': ['accessibility_apps', 'custom_rom', 'detector_apps', 'root_apps', 'shizuku_dhizuku', 'sus_apps', 'xposed'],
            'applySettingTemplates': [],
            'applySettingsPresets': ['accessibility', 'dev_options', 'input_method'],
            'extraAppList': ['org.frknkrc44.hma_oss', 'com.termux', 'com.termux.x11', 'com.resukisu.resukisu', 'com.github.standardadb', 'eu.sisik.hackendebug', 'org.client.scrcpy', 'com.droidspaces.app', 'gr.nikolasspyr.integritycheck', 'eu.xiaomi.ext'],
            'extraOppositeAppList': []
        })
        p_cfg['excludeSystemApps'] = False
        extra = p_cfg.setdefault('extraAppList', [])
        if 'eu.xiaomi.ext' not in extra:
            extra.append('eu.xiaomi.ext')
    with open(cfg_path, 'w') as f:
        json.dump(cfg, f, indent=2)
except Exception as e:
    sys.exit(0)
" 2>/dev/null || true
fi

# Broadcast reload request to HMA ServiceProvider
if [ -x "/system/bin/content" ] || command -v content >/dev/null 2>&1; then
    content call --uri content://org.frknkrc44.hma_oss.ServiceProvider --method reloadConfigFromFile >/dev/null 2>&1 || true
    echo "[+] HMA isolation configuration reloaded."
fi
