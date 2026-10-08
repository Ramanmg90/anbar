"""بعد از `flutter create`، مجوز دوربین و نام فارسی برنامه را به AndroidManifest اضافه می‌کند."""
import re
import sys

root = sys.argv[1] if len(sys.argv) > 1 else "."
path = f"{root}/android/app/src/main/AndroidManifest.xml"
s = open(path, encoding="utf-8").read()

if "android.permission.CAMERA" not in s:
    s = s.replace("<application", '<uses-permission android:name="android.permission.CAMERA"/>\n    <application', 1)
for feat in ("android.hardware.camera", "android.hardware.camera.autofocus"):
    if feat not in s:
        s = s.replace("<application", f'<uses-feature android:name="{feat}" android:required="false"/>\n    <application', 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="انبار پارچه‌سرا"', s, count=1)
open(path, "w", encoding="utf-8").write(s)
print("manifest patched")


# --- رفع ارور compileSdk پلاگین‌ها ---
# پلاگین‌هایی مثل file_picker با compileSdk 34 ساخته شده‌اند ولی
# flutter_plugin_android_lifecycle حداقل 36 می‌خواهد؛ پس همه‌ی کتابخانه‌ها را روی 36 می‌بریم.
import os

MARK = "// forced-compile-sdk"
KTS = f"""
{MARK}
subprojects {{
    fun forceSdk(p: Project) {{
        if (p.plugins.hasPlugin("com.android.library")) {{
            p.extensions.configure<com.android.build.gradle.LibraryExtension> {{
                compileSdk = 36
            }}
        }}
    }}
    if (state.executed) forceSdk(this) else afterEvaluate {{ forceSdk(this) }}
}}
"""
GROOVY = f"""
{MARK}
subprojects {{ sp ->
    def forceSdk = {{ p ->
        if (p.plugins.hasPlugin('com.android.library')) {{
            p.android {{ compileSdkVersion 36 }}
        }}
    }}
    if (sp.state.executed) forceSdk(sp) else sp.afterEvaluate {{ forceSdk(sp) }}
}}
"""
for name, block in (("build.gradle.kts", KTS), ("build.gradle", GROOVY)):
    gp = f"{root}/android/{name}"
    if os.path.exists(gp):
        g = open(gp, encoding="utf-8").read()
        if MARK not in g:
            open(gp, "w", encoding="utf-8").write(g + block)
        print(f"{name} patched (compileSdk 36 for plugins)")
        break
else:
    raise SystemExit("android/build.gradle(.kts) not found")
