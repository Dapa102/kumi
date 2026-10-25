"""Seed master data: achievements and Kumi dialogs. Idempotent."""

from sqlalchemy import select

from app.database import Base, SessionLocal, engine
from app.models import Achievement, KumiDialog

ACHIEVEMENTS = [
    (
        "first_steps",
        "Langkah Pertama",
        "Selesaikan tugas pertamamu",
        "badge_first",
        "total_completed",
        1,
    ),
    ("task_10", "Produktif", "Selesaikan 10 tugas", "badge_ten", "total_completed", 10),
    ("task_50", "Sangat Produktif", "Selesaikan 50 tugas", "badge_fifty", "total_completed", 50),
    ("streak_3", "Tiga Hari", "Streak 3 hari berturut-turut", "badge_fire3", "streak", 3),
    ("streak_7", "Seminggu Konsisten", "Streak 7 hari berturut-turut", "badge_fire7", "streak", 7),
    ("streak_30", "Sebulan Penuh", "Streak 30 hari berturut-turut", "badge_fire30", "streak", 30),
]

DIALOGS = [
    ("morning", "Selamat pagi! Hari ini kita mulai pelan-pelan, ya."),
    ("morning", "Pagi yang cerah! Mau lihat tugas pertama hari ini?"),
    ("morning", "Aku sudah bangun lebih dulu. Kamu juga sudah siap?"),
    ("afternoon", "Sudah makan siang? Setelah itu kita cek satu tugas, yuk."),
    ("afternoon", "Setengah hari sudah lewat. Satu langkah kecil masih berarti."),
    ("night", "Malam sudah datang. Bagaimana harimu?"),
    ("night", "Waktunya istirahat. Besok kita coba lagi, ya."),
    ("night", "Terima kasih sudah berusaha hari ini."),
    ("task_done", "Yeay! Satu tugas selesai. Aku bangga sama kamu!"),
    ("task_done", "Keren! Terus begini, nanti kita lihat streak-nya tumbuh."),
    ("task_done", "Selesai! Sedikit lagi menuju hari yang produktif."),
    ("idle", "Belum ada tugas hari ini. Mau tambah satu?"),
    ("idle", "Aku menunggu di sini. Kalau butuh bantuan, ketuk saja aku."),
]


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        existing_codes = set(db.scalars(select(Achievement.code)).all())
        for code, name, description, icon, criteria_type, criteria_value in ACHIEVEMENTS:
            if code in existing_codes:
                continue
            db.add(
                Achievement(
                    code=code,
                    name=name,
                    description=description,
                    icon=icon,
                    criteria_type=criteria_type,
                    criteria_value=criteria_value,
                )
            )

        if (db.scalar(select(KumiDialog.id).limit(1))) is None:
            for context, text in DIALOGS:
                db.add(KumiDialog(context=context, text=text))

        db.commit()


if __name__ == "__main__":
    seed()
    print("Seed complete.")
