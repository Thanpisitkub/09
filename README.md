# Throw Food For Animals — Stage 2: runway map + plots + mobile deploy

**ยังไม่ได้ทดสอบใน Roblox Studio** (ไม่มี Studio ในสภาพแวดล้อมที่เขียน) ตรวจได้แค่โครงสร้างโค้ด รันครั้งแรกอาจมี error ให้แก้ทีละจุด

## แมปแบบเกมต้นฉบับ (สนามวิ่งยาว)
- ทุกคนยืนที่ **ฐานของตัวเอง** (10 ช่อง เรียงข้างกันที่ต้นสนาม) แล้วขว้างอาหารไปตามสนามยาวไปทาง -Z
- สนามแบ่งเป็น **12 โซน** ต่อกันเป็นเส้นตรง: ขว้างไกลแค่ไหน = ตกโซนไหน (ไม่มีเมนูเลือกพื้นที่แล้ว) ระยะเริ่มโซนอยู่ใน `Config.World.ZoneStarts`
- ขว้างไกลขึ้น = โชคเพิ่มสูงสุด +50% ที่ปลายสนาม; อาหารและ Luck ยังกำหนดชนิดสัตว์เหมือนเดิม
- แต่ละโซนมีพื้น ฉากประดับ แสง/หมอกของตัวเอง ป้ายชื่อโซน เสาประตู และป้ายระยะทุก 100 studs
- ในฐาน: จุดขว้างเรืองแสง, บาร์ดึงขึ้น (กดแล้วเปิดเทรน), ร้านอาหาร, ป้ายสัตว์, ป้ายแผนที่, ป้ายชื่อเจ้าของ, คอกสัตว์ที่สัตว์ซึ่งวางไว้เดินเล่นจริง
- ทั้งโลกสร้างจากโค้ด (`WorldBuilder.luau`) ไม่ต้องใช้ Studio วางของ

## ส่งขึ้น Roblox จากมือถือ (ไม่ใช้ Studio)
GitHub Actions จะรัน Rojo สร้างไฟล์เกมแล้วอัปโหลดผ่าน Open Cloud ให้เอง (ไฟล์ `.github/workflows/publish.yml`)

**ตั้งค่าครั้งเดียว**
1. สร้างเกมเปล่า (Experience) ที่ create.roblox.com → Creations ตั้งเป็น Private ไว้ก่อน แล้วจด **Universe ID** และ **Place ID** (ในหน้า Creations → เปิดเกม → Places)
2. Creator Dashboard → Open Cloud → API Keys → สร้างคีย์: เพิ่ม **universe-places** ใน Access Permissions, ใส่การดำเนินการ **Write**, เลือกเกมนี้ แล้วคัดลอกคีย์ (จะเห็นแค่ครั้งเดียว)
3. สร้าง GitHub repo (ตั้งเป็น Private) แล้วใน Settings → Secrets and variables → Actions:
   - Secret: `ROBLOX_API_KEY` = คีย์
   - Variables: `ROBLOX_UNIVERSE_ID`, `ROBLOX_PLACE_ID`
4. ใน Termux: `pkg install git gh unzip` → `unzip ThrowFoodForAnimals.zip && cd TFFA` → `bash setup.sh`
   สคริปต์จะถาม Universe ID, Place ID, API Key แล้วสร้าง repo ส่วนตัว ตั้ง secret/variable และ push ให้เอง (ข้อ 3 ข้างบนไม่ต้องทำมือ)

**ใช้งานประจำ:** แก้ไฟล์แล้ว push เข้า `main` ระบบจะ build + publish เอง (หรือกด Run workflow ที่แท็บ Actions แล้วเลือก Published/Saved) ผลสำเร็จจะเห็นเลขเวอร์ชัน แล้วเปิดเกมในแอป Roblox ที่ล็อกอินบัญชีเจ้าของเพื่อทดสอบ

**ดู error บนมือถือ:** ในเกม พิมพ์ `/console` ในแชท (เฉพาะเจ้าของเกม) เปิด Developer Console แท็บ Server/Client เพื่อดู log

**ข้อควรรู้**
- Place Publishing API จำกัด 10 ครั้ง/นาที และไม่อัปเดตอินสแตนซ์บางชนิด (EditableImage, EditableMesh, PartOperation, SurfaceAppearance, BaseWrap) — โปรเจกต์นี้ยังไม่ใช้
- ทุกครั้งที่ publish จะทับทั้ง place ไฟล์ที่ตั้งค่าใน Studio จะหาย ให้แก้ผ่านโค้ด/`default.project.json`
- ถ้าอยากเปิดให้เล่นจริง ให้เปลี่ยนเกมจาก Private เป็น Public ที่หน้าตั้งค่าเกม
- ถ้า workflow ติดตั้ง Rojo ไม่ได้ ให้เปลี่ยน `ROJO_VERSION` เป็นเวอร์ชันที่มีใน github.com/rojo-rbx/rojo/releases

## ติดตั้งแบบเดิม (มี Studio)
`rojo serve` → Connect ใน Studio, เปิด Enable Studio Access to API Services, ใส่ UserId ของคุณที่ `Config.Admin.StudioCreatorUserId` เพื่อทดสอบเมนูแอดมิน

## โครงสร้าง
| ที่อยู่ | ไฟล์ |
|---|---|
| ReplicatedStorage/Shared | Theme, Kit, Catalog, Config, Net, ThrowMath, ZoneLook, Util |
| ReplicatedStorage/Client | Main, State, Throw, WorldClient, UI/* |
| ServerScriptService | Main + Services/{PlayerData, Economy, WorldBuilder, Plots, Throw, AdminLog, AdminPermissions, AdminSecurity, AdminService} |
| ServerStorage | AdminClient (ส่งให้เฉพาะแอดมิน) |

## ยังไม่ได้ทำ
โมเดล/อนิเมชันสัตว์จริง, เส้นทางที่สัตว์วิ่งมาหาอาหารที่ตก, ปุ่มขายสัตว์, Quests/Daily/Achievements/Leaderboard เต็มรูปแบบ, เสียง/เพลง, กล้องซีนีมาติก, session lock ข้ามเซิร์ฟเวอร์
> หน้าตาจริงของเกมต้นฉบับผมดูไม่ได้ (อ้างอิงจากคำอธิบายในเว็บไกด์) ถ้ามีภาพหน้าจอส่งมา ผมปรับเลย์เอาต์ให้ใกล้เคียงขึ้นได้
