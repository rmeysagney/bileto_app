import os
import django
import sys
from datetime import datetime, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth import get_user_model
from events.models import Category, Event

User = get_user_model()

def populate():
    # 1. Admin / Organizer kullanıcı
    organizer, _ = User.objects.get_or_create(
        username='admin',
        defaults={
            'email': 'admin@etkinlik.com',
            'first_name': 'Sistem',
            'last_name': 'Yöneticisi',
            'is_organizer': True,
            'is_staff': True,
            'is_superuser': True
        }
    )
    if not organizer.check_password('admin123'):
        organizer.set_password('admin123')
        organizer.save()

    # 2. Eski etkinlikleri temizle ki çakışma/eski veri kalmasın!
    Event.objects.all().delete()

    # 3. Kategoriler
    def get_cat(name, slug, icon):
        cat = Category.objects.filter(name=name).first() or Category.objects.filter(slug=slug).first()
        if not cat:
            cat = Category.objects.create(name=name, slug=slug, icon=icon)
        return cat

    cat_konser = get_cat('Konser', 'konser', 'music_note')
    cat_tiyatro = get_cat('Tiyatro', 'tiyatro', 'theater_comedy')
    cat_standup = get_cat('Stand Up', 'stand-up', 'mic')
    cat_festival = get_cat('Festival', 'festival', 'festival')

    # 4. Yüksek Kaliteli Bubilet Afiş ve Etkinlik Görselleri
    now = datetime.now()

    sample_events = [
        {
            'title': 'Mabel Matiz Harbiye Konserleri',
            'description': 'Mabel Matiz, Atlantis Yapım organizasyonuyla 25-26 Temmuz tarihlerinde Paribu Harbiye Açıkhava Konserleri kapsamında Harbiye Açıkhava\'da sevenleriyle buluşacak.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=2, hours=4),
            'end_datetime': now + timedelta(days=2, hours=7),
            'location_name': 'Harbiye Cemil Topuzlu Açıkhava Tiyatrosu',
            'city': 'İstanbul',
            'capacity': 500,
            'price': '1400.00',
            'is_free': False,
        },
        {
            'title': 'Melike Şahin Konseri',
            'description': 'Diva Melike Şahin, tutkulu şarkıları ve eşsiz sahne performansıyla Harbiye Açıkhava seyircisini büyülüyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=4, hours=3),
            'end_datetime': now + timedelta(days=4, hours=6),
            'location_name': 'Harbiye Cemil Topuzlu Açıkhava Tiyatrosu',
            'city': 'İstanbul',
            'capacity': 500,
            'price': '2750.00',
            'is_free': False,
        },
        {
            'title': 'Ata Demirer Gazinosu',
            'description': 'Ata Demirer, Türk müziği repertuarı ve kahkaha dolu komedi gösterisiyle Harbiye Açıkhava sahnede!',
            'category': cat_standup,
            'image': 'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=10, hours=2),
            'end_datetime': now + timedelta(days=10, hours=5),
            'location_name': 'Harbiye Cemil Topuzlu Açıkhava Tiyatrosu',
            'city': 'İstanbul',
            'capacity': 450,
            'price': '3520.00',
            'is_free': False,
        },
        {
            'title': 'Gökhan Türkmen Konseri',
            'description': 'Romantik şarkıların efsane ismi Gökhan Türkmen, Harbiye Açıkhava Tiyatrosu\'nda büyülü bir akşam vaat ediyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=1, hours=2),
            'end_datetime': now + timedelta(days=1, hours=5),
            'location_name': 'Harbiye Cemil Topuzlu Açıkhava Tiyatrosu',
            'city': 'İstanbul',
            'capacity': 300,
            'price': '1500.00',
            'is_free': False,
        },
        {
            'title': 'Saint Levant "Afandi World Tour"',
            'description': 'Filistin asıllı yükselen yıldız Saint Levant, unutulmaz bir gece için Volkswagen Arena sahnesinde sevenleriyle buluşuyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=3, hours=4),
            'end_datetime': now + timedelta(days=3, hours=7),
            'location_name': 'Volkswagen Arena',
            'city': 'İstanbul',
            'capacity': 500,
            'price': '3000.00',
            'is_free': False,
        },
        {
            'title': 'Nil Karaibrahimgil - Senfonik Konser',
            'description': 'Nil Karaibrahimgil en sevilen şarkılarını senfoni orkestrası eşliğinde Zorlu PSM Turkcell Sahnesi\'nde seslendiriyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=5, hours=3),
            'end_datetime': now + timedelta(days=5, hours=6),
            'location_name': 'Zorlu PSM',
            'city': 'İstanbul',
            'capacity': 400,
            'price': '1850.00',
            'is_free': False,
        },
        {
            'title': 'Ajda Pekkan Senfonik',
            'description': 'Süperstar Ajda Pekkan, unutulmaz hitlerini dev orkestra eşliğinde Harbiye Açıkhava sahnesinde seslendiriyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=8, hours=3),
            'end_datetime': now + timedelta(days=8, hours=6),
            'location_name': 'Harbiye Cemil Topuzlu Açıkhava Tiyatrosu',
            'city': 'İstanbul',
            'capacity': 600,
            'price': '1870.00',
            'is_free': False,
        },
        {
            'title': 'Semicenk Canlı Performans',
            'description': 'Son dönemin rekorlar kıran ismi Semicenk, hit parçalarıyla Blind İstanbul sahnesinde.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=6, hours=4),
            'end_datetime': now + timedelta(days=6, hours=7),
            'location_name': 'Blind İstanbul',
            'city': 'İstanbul',
            'capacity': 350,
            'price': '1750.00',
            'is_free': False,
        },
        {
            'title': 'Yıldız Tilbe Harbiye Konserleri',
            'description': 'Türk pop müziğinin efsane sesi Yıldız Tilbe, Harbiye Açıkhava sahnesinde unutulmaz bir gece yaşatacak.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=12, hours=3),
            'end_datetime': now + timedelta(days=12, hours=6),
            'location_name': 'Jolly Joker Kadıköy',
            'city': 'İstanbul',
            'capacity': 5,
            'price': '1900.00',
            'is_free': False,
        },
        {
            'title': 'Amr Diab Live in Istanbul',
            'description': 'Dünyaca ünlü yıldız Amr Diab, IF Performance Hall Beşiktaş sahnesinde sevenleriyle buluşuyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=15, hours=4),
            'end_datetime': now + timedelta(days=15, hours=7),
            'location_name': 'IF Performance Hall Beşiktaş',
            'city': 'İstanbul',
            'capacity': 700,
            'price': '4500.00',
            'is_free': False,
        },
        {
            'title': 'Duman Canlı Performans',
            'description': 'Türk rock müziğinin dev ismi Duman, en sevilen parçalarıyla sahnede coşkulu bir gece vaat ediyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(hours=5),
            'end_datetime': now + timedelta(hours=8),
            'location_name': 'Blind İstanbul',
            'city': 'İstanbul',
            'capacity': 500,
            'price': '1200.00',
            'is_free': False,
        },
        {
            'title': 'Adamlar Canlı Konser',
            'description': 'Adamlar grubu, enerjik performansları ve şarkılarıyla dinleyicileriyle buluşuyor.',
            'category': cat_konser,
            'image': 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?auto=format&fit=crop&w=1200&q=80',
            'start_datetime': now + timedelta(days=1, hours=6),
            'end_datetime': now + timedelta(days=1, hours=9),
            'location_name': 'Jolly Joker Kadıköy',
            'city': 'İstanbul',
            'capacity': 300,
            'price': '950.00',
            'is_free': False,
        }
    ]

    for data in sample_events:
        Event.objects.create(
            organizer=organizer,
            title=data['title'],
            description=data['description'],
            category=data['category'],
            image=data['image'],
            start_datetime=data['start_datetime'],
            end_datetime=data['end_datetime'],
            location_name=data['location_name'],
            city=data['city'],
            capacity=data['capacity'],
            price=data['price'],
            is_free=data['is_free']
        )

    print(f"Eski veriler temizlendi ve 12 yeni etkinlik HD afişleriyle yüklendi!")

if __name__ == '__main__':
    populate()
