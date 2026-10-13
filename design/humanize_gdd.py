"""Edit Indonesian prose in place while retaining tables, figures and formatting."""
from pathlib import Path
import re
from collections import Counter
from docx import Document

path=Path(__file__).parent/'Bullet Mania Game Design Document.docx'
doc=Document(path)
rewrites={
'Dokumen ini menjelaskan cara bermain': 'Dokumen ini menjelaskan cara bermain Bullet Mania, cara kerja sistemnya, dan hal yang masih perlu diuji. Kami menggunakannya sebagai acuan untuk memperbaiki prototipe dan melanjutkan pengembangan.',
'Bullet Mania adalah game bullet hell untuk satu pemain': 'Bullet Mania adalah game bullet hell bertema neon untuk satu pemain. Pemain mengendalikan kapal yang menembak otomatis, menghindari proyektil, mengumpulkan peningkatan, lalu menghadapi tiga bos dalam tiga sektor. Pemain perlu membaca pola serangan, menjaga inti tabrakan kapal, dan memilih waktu yang tepat untuk memakai pertahanan.',
'Status: prototipe telah diimplementasikan.': 'Prototipe sudah dibuat dan sebelumnya berhasil dikompilasi dengan runtime GameMaker 2026.0.0.23 untuk Windows VM. Permainan satu putaran penuh, tampilan saat dimainkan, dan keseimbangannya masih perlu diuji.',
'Bagian 1–10 mengikuti struktur': 'Bagian 1–10 mengikuti susunan materi GCD Ch7 GDD. Aturan dan angka diambil dari kode saat ini. Bagian bertanda Usulan, termasuk sasaran pemain, cerita, dan audio, masih berupa rencana dan belum diuji atau tersedia dalam game. Nama karakter dan label menu tetap memakai nama aslinya agar mudah dicocokkan saat bermain.',
'Acuan struktur:': 'Susunan dokumen mengacu pada GCD - Ch7 - GDD.pptx, Bab 7 Game Design Document, Informatics Engineering, Universitas Surabaya, terutama slide 18–41. Contoh dari materi dipakai untuk memahami cara menyusun GDD; fitur Bullet Mania dijelaskan berdasarkan proyeknya sendiri.',
'Sumber proyek:': 'Isi teknis diperiksa dari Bullet Mania.yyp, rooms/Room1/Room1.yy, objects/obj_game/Create_0.gml, Step_0.gml, Draw_0.gml, README.md, dan lembar karakter. Versi 1.0 mencatat kondisi prototipe pada 8 Oktober 2026. Dokumen perlu diperbarui setelah aturan berubah atau pengujian selesai.',
'Bullet Mania adalah game tembak-menembak arcade': 'Bullet Mania adalah game tembak-menembak arcade yang dilihat dari atas. Pemain menggerakkan kapal sian dalam arena tetap, sementara kapal menembak otomatis ke atas. Satu putaran berisi enam formasi musuh dan tiga bos.',
'Prototipe mencakup gerakan': 'Prototipe sudah memiliki gerakan, fokus, dash, tembakan otomatis, pulse, item peningkat, tiga bos, dan dua toko. Menu mencakup pengisian nama, papan peringkat lokal, pengaturan tombol, batas FPS, VSync, jeda, dan pengulangan permainan. Karakter dan lingkungan digambar dengan bentuk geometris melalui kode.',
'Belum tersedia papan peringkat daring': 'Game belum memiliki papan peringkat daring, mode multipemain, kampanye cerita, audio, gamepad, atau peningkatan permanen. Data yang disimpan adalah pengaturan, rekor skor, dan sepuluh besar lokal. Kredit dan pembelian hanya berlaku untuk putaran yang sedang dimainkan.',
'Bullet Mania dirancang agar medan proyektil': 'Kami ingin pemain tetap bisa menemukan jalan di antara proyektil yang padat. Fokus membantu saat melewati celah sempit, sedangkan dash dan pulse bisa dipakai ketika jalan mulai tertutup. Karena kapal menembak otomatis, pemain dapat lebih memperhatikan posisi dan pertahanan. Proyektil yang hanya melewati bagian luar kapal tidak mengenai pemain selama tidak menyentuh inti putihnya.',
'Kesulitan berkembang melalui pertemuan': 'Tantangan bertambah lewat musuh yang berbeda di arena yang sama. Formasi biasa memperkenalkan tembakan terarah, lingkaran, dan kipas. Bos memakai kombinasi pola tersebut dan mengganti serangan saat kesehatannya berkurang. Setelah bos kalah, pemain mendapat pemulihan dan kesempatan berbelanja sebelum sektor berikutnya. Di toko, pemain dapat memperbaiki kapal, menambah pertahanan, atau meningkatkan reaktor dash sesuai kebutuhan.',
'Pengalaman yang dituju adalah': 'Kami berharap pemain merasa tegang saat bertempur dan lega setelah berhasil. Toko memberi waktu untuk memilih peningkatan sebelum melanjutkan, sedangkan hasil permainan diharapkan mendorong pemain mencoba lagi. Harapan ini masih perlu diuji. Warna kontras, kilatan saat terkena serangan, jejak gerakan, dan pengumuman membantu pemain memahami kejadian. Efeknya tidak boleh menutupi proyektil. Pemain baru diharapkan bisa belajar, sementara pemain yang lebih berpengalaman dapat mengejar skor lewat lintasan dekat proyektil dan penggunaan sumber daya yang hemat.',
'Bahaya yang terbaca.': 'Inti pemain, proyektil bulat, dan item berbentuk belah ketupat harus mudah dibedakan. Peringatan bos menunjukkan tempat hujan proyektil akan jatuh.',
'Bertahan dengan presisi.': 'Pemain dapat memakai fokus, dash, perisai, atau pulse untuk bertahan. Masing-masing punya batas penggunaan, sehingga pemain perlu memperhatikan waktu dan posisi.',
'Pilihan yang mengubah putaran.': 'Item dan pembelian meningkatkan kapal selama putaran berjalan. Setelah selesai, pemain bisa mencoba lagi untuk memperbaiki posisinya di papan peringkat lokal.',
'Fitur baru harus mendukung': 'Fitur baru sebaiknya membantu pemain membaca pola, memilih cara bertahan, atau berkembang selama putaran. Fitur lain dapat ditunda sampai permainan saat ini sudah diuji dan terasa stabil serta menyenangkan.',
'Usulan sasaran:': 'Game ini ditujukan untuk pemain PC yang menyukai aksi arcade, mau mencoba berulang kali, dan senang mempelajari pola serangan. Perbandingan skor dilakukan pada komputer yang sama. Sasaran ini masih berupa usulan. Sesi bermain diharapkan singkat, tetapi durasinya belum diukur.',
'Seorang mahasiswa bermain di laptop': 'Sebagai contoh, seorang mahasiswa bermain di laptop saat ada waktu luang. Ia sudah tahu WASD, tetapi belum terbiasa menghindari banyak proyektil. Ia membutuhkan petunjuk sederhana, inti tabrakan yang terlihat, dan cara memperlambat gerakan. Setelah beberapa kali bermain, ia ingin mengenali pola Helix Warden dan melewati skor teman pada komputer yang sama. Contoh ini belum didasarkan pada penelitian pemain.',
'Flight Manual menjelaskan': 'Flight Manual menjelaskan kontrol dan item. Pemain bisa mengganti tombol sesuai susunan papan ketiknya. Menu juga dapat dibuka dengan tombol tetap atau tetikus, dan FPS dapat disesuaikan dengan perangkat.',
'Informasi warna diperkuat': 'Bentuk dan teks membantu membedakan objek selain warnanya. Item memakai simbol, perisai memakai lingkaran, dan setiap bos memiliki bentuk berbeda. Pengaturan intensitas kilatan, pengurangan guncangan kamera, petunjuk awal yang lebih jelas, dan navigasi gamepad masih berupa usulan.',
'Pemain membaca pola, bergerak': 'Pemain mencari celah dalam pola serangan dan bergerak melewatinya, sambil kapal terus menembak otomatis. Fokus membantu gerakan yang lebih hati-hati. Dash atau pulse dapat dipakai saat terdesak. Mengalahkan musuh menghasilkan skor, kredit, dan item. Setelah bos kalah, pemain memulihkan kapal dan berbelanja sebelum masuk sektor berikutnya.',
'Kemenangan diperoleh dengan': 'Pemain menang setelah mengalahkan Prism Engine melalui dua sektor sebelumnya. Pemain kalah jika kesehatannya habis. Putaran baru dimulai dengan lima kesehatan, tiga pulse, senjata tingkat 1, tanpa perisai atau peningkatan dash, dan nol kredit. Skor dari hasil menang atau kalah masuk ke papan peringkat lokal. Permainan yang ditinggalkan tidak dicatat.',
'W meningkatkan senjata sampai': 'Item W menaikkan senjata sampai tingkat 3. S menambah perisai sampai dua, + memulihkan kesehatan sampai lima, dan P mengisi pulse sampai tiga. Setiap musuh biasa ketiga yang dikalahkan pasti menjatuhkan item; musuh lain memiliki peluang 15%. Musuh ketiga dan keenam menjatuhkan W. Dua bos pertama juga menjatuhkan W dan S.',
'Musuh biasa memberi 25,': 'Musuh biasa memberi 25, 35, atau 45 kredit, sedangkan bos memberi 250, 350, atau 450. Kredit dihitung terpisah dari skor. Toko tidak mengenakan biaya jika dana kurang atau kapasitas penuh. Item, reaktor, dan kredit hanya berlaku untuk putaran yang sedang berjalan.',
'Tiga sektor logis menggunakan': 'Ketiga sektor memakai satu arena tetap. Latar bergerak, tetapi kamera dan ruang tabrakan tetap pada tempatnya. Setiap sektor berisi dua formasi musuh dan satu bos. Arena berada di bawah HUD, dengan pemain bergerak di bagian bawahnya.',
'Formasi mencoba mundur setelah': 'Formasi mencoba mundur setelah 25 detik. Namun, kode gerakannya juga menarik musuh kembali ke ketinggian formasi, sehingga musuh mungkin tidak keluar dari arena. Bagian ini perlu diperiksa sebelum batas waktu dipakai untuk melanjutkan tahap.',
'Usulan cerita:': 'Usulan cerita kami menempatkan pilot dalam simulasi pertahanan neon yang dikunci oleh tiga penjaga. Helix Warden mengatur jalur energi berputar, Ion Tempest mengendalikan badai yang jatuh, dan Prism Engine mengatur reaktor terakhir. Pilot harus menonaktifkan ketiganya untuk memulihkan sinyal.',
'Kerangka ini menyatukan': 'Cerita ini menghubungkan bos dan urutan sektor tanpa perlu dialog atau adegan sinematik. Ceritanya belum muncul langsung dalam game. Saat ini, tema disampaikan melalui nama Pilot Sign-In, Signal Lost, Storm Cleared, dan Neon Supply.',
'Arena merupakan ruang': 'Arena digambarkan sebagai ruang pertempuran digital. Bentuk geometris mewakili mesin dan energi. Proyektil memakai pola berulang yang bisa dipelajari. Inti suplai meningkatkan kapal selama percobaan berjalan. Kekalahan mengakhiri sinyal, lalu pemain dapat mengulang simulasi dengan nama pilot yang sama.',
'Tema disampaikan melalui': 'Tema muncul lewat label singkat, nama bos, dan teks hasil. Kami mengusulkan pengantar satu kalimat serta subjudul sektor. Cerita bercabang, karakter bersuara, adegan sinematik, dan sistem dialog belum masuk cakupan. Pemain tetap harus memahami cara bermain meskipun tidak mengikuti ceritanya.',
'Visual menggunakan garis': 'Tampilan game memakai garis neon, bentuk geometris, inti bercahaya, dan kisi biru gelap. Semua bentuk digambar melalui kode. Game tidak memakai ilustrasi karakter impor atau aset buatan AI.',
'Lembar referensi karakter': 'Lembar karakter menunjukkan bentuk yang diperbesar dari gambar berbasis kode. Nama pada gambar tetap mengikuti label dalam game. Saat dimainkan, bentuk-bentuk tersebut berputar dan bergerak.',
'Transisi memudar, tombol bergeser': 'Perubahan layar memakai transisi memudar dan tombol yang bergeser. Di dalam game, kapal miring saat bergerak dan meninggalkan jejak dash. Kilatan peluru, lingkaran benturan, lampu item, serta indikator kesehatan memberi tahu pemain apa yang terjadi. Efek ini perlu diuji agar jalur peluru dan inti tabrakan tetap terlihat, terutama saat pulse menyala atau cahaya proyektil bertumpuk.',
'Audio belum diimplementasikan.': 'Game belum memiliki audio. Kami mengusulkan musik synth orisinal yang meningkat saat menghadapi bos, suara singkat saat mengambil item atau membeli peningkatan, dan tanda berbeda untuk kerusakan, dash yang siap, serta fase bos. Peringatan visual harus tetap jelas ketika suara dimatikan. Audio dan lisensinya masih perlu dikerjakan.',
'Pilot Sign-In muncul setiap': 'Setiap kali aplikasi dibuka, pemain mengisi nama melalui Pilot Sign-In. Nama tidak boleh kosong, panjangnya maksimal 12 karakter, dan diubah menjadi huruf besar. Nama tetap dipakai saat mengulang permainan. Menu utama menyediakan Start Run, How to Play, Options, Leaderboard, dan Quit Game.',
'HUD atas menampilkan': 'Bagian atas layar menampilkan skor, rekor, kesehatan, pulse, kesiapan dash, tingkat senjata, perisai, dan kredit. Saat melawan bos, nama, fase, dan kesehatannya muncul di bawah HUD. Titik putih pada kapal adalah inti tabrakan. Pemberitahuan item muncul dekat bagian bawah arena.',
'Options memuat': 'Menu Options berisi Key Bindings, Frame Rate, V Sync, Reset Best Score, dan Back. Saat mengganti tombol, pemain perlu melepas tombol konfirmasi sebelum menekan tombol baru. Jika tombol sudah dipakai, kedua fungsi akan ditukar. Escape membatalkan perubahan. Pengaturan tersimpan otomatis. Pilihan FPS adalah 30, 60, 120, 144, dan 240. VSync aktif secara bawaan dan dapat membatasi FPS mengikuti monitor.',
'Reset Best Score meminta': 'Reset Best Score membuka konfirmasi dengan Cancel sebagai pilihan awal. Opsi ini hanya menghapus rekor tunggal; papan peringkat tetap tersimpan. Penjelasan pada menu perlu diperjelas agar pemain memahami perbedaannya.',
'Sepuluh besar lokal menyimpan': 'Papan peringkat lokal menyimpan sepuluh skor terbaik, masing-masing berdasarkan skor tertinggi suatu nama dari putaran yang selesai. Status menang atau kalah ikut dicatat, dan nama pemain aktif disorot. Skor seri mempertahankan urutan sebelumnya. Jika pemain menang dengan skor yang sama, status kekalahannya dapat diganti. Game belum memakai layanan daring atau autentikasi akun. Dari layar hasil, pemain dapat mengulang, melihat papan peringkat, atau kembali ke menu utama.',
'Prototipe telah mencakup': 'Prototipe sudah memiliki tiga sektor dan menu pendukung. Selanjutnya, permainan perlu diuji secara lengkap. Gambar tetap dibuat melalui kode. Perubahan aturan waktu dan ekonomi perlu dicatat bersama hasil pengujiannya.',
'GameMaker memakai satu pengendali': 'GameMaker memakai satu pengendali obj_game di Room1. Create berisi sistem dan metode simulate. Step menangani menu dan akumulasi waktu, sementara Draw menggambar bentuk. Simulasi berjalan pada 60 Hz; animasi menu mengikuti waktu nyata. Waktu per frame dibatasi 100 ms agar simulasi tidak mengejar terlalu banyak langkah setelah gangguan. Gerakan belum diinterpolasi antarlangkah, sehingga FPS tinggi saja belum tentu membuat gerakan objek lebih halus.',
}

numbers=lambda text:Counter(re.findall(r'\d+(?:[.,]\d+)*',text))
changed=0
for para in doc.paragraphs:
    old=para.text
    new=next((value for prefix,value in rewrites.items() if old.startswith(prefix)),old)
    # Numerical ranges retain their values; punctuation is changed only in prose.
    new=new.replace('–',' sampai ').replace('—',', ')
    if old!=new:
        assert numbers(old)==numbers(new),(old,new)
        # Retain paragraph style, spacing, and the existing run formatting.
        if para.runs:
            para.runs[0].text=new
            for run in para.runs[1:]:run.text=''
        else:para.add_run(new)
        changed+=1
for tab in doc.tables:
    for row in tab.rows:
        for cell in row.cells:
            for para in cell.paragraphs:
                for run in para.runs:
                    run.text=run.text.replace('–',' sampai ').replace('—',', ')
all_text='\n'.join(p.text for p in doc.paragraphs)
for required in ['Delon Villarer Agnata','160423164','Henry Hilton','160423172']:
    assert required in all_text
doc.save(path)
print(f'{changed} paragraf diperbarui; angka, nama, dan NRP diperiksa.')
