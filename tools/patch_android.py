"""بعد از `flutter create`، مجوز دوربین، نام برنامه (RoboFabric) و آیکون را به پروژه‌ی اندروید اضافه می‌کند."""
import os
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
s = re.sub(r'android:label="[^"]*"', 'android:label="RoboFabric"', s, count=1)
open(path, "w", encoding="utf-8").write(s)
print("manifest patched")

# --- آیکون برنامه (از پوشه‌ی android_res کنار این اسکریپت) ---
import shutil
_src = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "android_res", "res")
_dst = f"{root}/android/app/src/main/res"
if os.path.isdir(_src):
    shutil.copytree(_src, _dst, dirs_exist_ok=True)
    print("launcher icon copied")
else:
    print("WARNING: android_res/res not found; default icon kept")


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


# --- خاموش کردن R8 در بیلد release ---
# R8 کد کتابخانه‌های دوربین (CameraX / ML Kit) را خراب می‌کند و اسکنر با خطای
# «Attempt to invoke virtual method ... on a null object reference» بالا نمی‌آید.
# پرچم `flutter build --no-shrink` اثری ندارد؛ راه درست این property است.
gp = f"{root}/android/gradle.properties"
props = open(gp, encoding="utf-8").read() if os.path.exists(gp) else ""
if "\nshrink=" not in "\n" + props:
    with open(gp, "a", encoding="utf-8") as fh:
        if props and not props.endswith("\n"):
            fh.write("\n")
        fh.write("shrink=false\n")
print("gradle.properties: shrink=false")
