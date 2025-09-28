
-- ============================================
-- A. VERİ TABANI TASARIMI
-- ============================================

-- Ana veritabanına geçiş yap
USE master;
GO

-- Veritabanı varsa, önce tüm bağlantıları kes ve sonra silmek için 
IF DB_ID('e_ticaretDB') IS NOT NULL
BEGIN
    ALTER DATABASE e_ticaretDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE e_ticaretDB;
END
GO

-- Database oluşturalım

CREATE DATABASE e_ticaretDB;
GO

-- Use Komutu ile database'i alalım

USE e_ticaretDB;
GO

-- Tablo Oluştuyoruz

/*

	* Musteri → Siparis (1:N)
	* Siparis → Siparis_Detay (1:N) + ON DELETE CASCADE
	* Urun → Kategori (N:1)
	* Urun → Satici (N:1)
	* Siparis_Detay → Urun (N:1)

Kurallar : 
	Bir müşteri birden fazla sipariş verebilir (Siparis.musteri_id → Musteri.id)
	Bir sipariş birden fazla ürün içerebilir (Siparis_Detay.siparis_id → Siparis.id ve Siparis_Detay.urun_id → Urun.id)
	Bir ürünün bir kategorisi vardır (Urun.kategori_id → Kategori.id)
	Bir ürün bir satıcıya aittir (Urun.satici_id → Satici.id)

Sırasıyla adım adım tablomuzu oluşturmak için, Primary Key ve Foreign Keyleri belirliyoruz. 
Aslında diyagramı iyi yazmak ve tablolar arası ilişkilendirmeyi iyi analiz etmek doğru sonuçlar 
üretecek tablolar oluşturmamızı sağlar.

*/

-- Öncelikle Bağımlılıkları olmayan tabloları inşa ediyoruz.
-- Sonra bağımlılıkları olan tabloları ekliyoruz.

-- Müşteri TABLOSU

CREATE TABLE Musteri (
	id				INT IDENTITY(1,1) PRIMARY KEY,
	ad				NVARCHAR(50) NOT NULL,
	soyad			NVARCHAR(50) NOT NULL,
	email			NVARCHAR(50) NOT NULL UNIQUE,
	sehir			NVARCHAR(50) NOT NULL,
	kayit_tarihi	DATETIME2 DEFAULT GETDATE()
	);
GO

-- Kategori TABLOSU

CREATE TABLE Kategori (
    id		INT IDENTITY(1,1) PRIMARY KEY,
    ad		NVARCHAR(255) NOT NULL UNIQUE
	);
GO


-- Satıcı TABLOSU

CREATE TABLE Satici (
	id		INT IDENTITY(1,1) PRIMARY KEY,
	ad		NVARCHAR(100) NOT NULL UNIQUE,
	adres	NVARCHAR(255) NULL
	);
GO

-- Ürün TABLOSU

CREATE TABLE Urun (
	id			INT IDENTITY(1,1) PRIMARY KEY,
	ad			NVARCHAR(100) NOT NULL,
	fiyat		DECIMAL(10,2) NOT NULL CHECK (fiyat >= 0),
	stok		INT NOT NULL DEFAULT 0 CHECK (stok >= 0),
	kategori_id INT NOT NULL,
	satici_id	INT NOT NULL,

	CONSTRAINT FK_Urun_Kategori FOREIGN KEY (kategori_id)
		REFERENCES Kategori(id),

	CONSTRAINT FK_Urun_Satici FOREIGN KEY (satici_id)
		REFERENCES Satici(id)
	);
GO


-- Sipariş TABLOSU

CREATE TABLE Siparis (
	id				INT IDENTITY(1,1) PRIMARY KEY,
	musteri_id		INT NOT NULL,
	tarih			DATETIME2 DEFAULT GETDATE(),
	toplam_tutar	DECIMAL(12, 2) NOT NULL CHECK (toplam_tutar >=0),
	odeme_turu		NVARCHAR(50) NOT NULL,

	CONSTRAINT FK_Siparis_Musteri FOREIGN KEY (musteri_id)
		REFERENCES Musteri(id)
	);
GO

-- Sipariş Detay TABLOSU

CREATE TABLE Siparis_Detay (
	id			INT IDENTITY (1,1) PRIMARY KEY,
	siparis_id	INT NOT NULL,
	urun_id		INT NOT NULL,
	adet		INT NOT NULL CHECK (adet > 0),
	fiyat		DECIMAL(10, 2) NOT NULL CHECK (fiyat >= 0),

	CONSTRAINT FK_SiparisDetay_Siparis FOREIGN KEY (siparis_id) 
        REFERENCES Siparis(id) ON DELETE CASCADE, --> SİPARİŞ SİLİNİNCE DETAYI DA SİLİNSİN.

    CONSTRAINT FK_SiparisDetay_Urun FOREIGN KEY (urun_id) 
        REFERENCES Urun(id)
	);
GO


-- ============================================
-- B. İNDEKSLER
-- ============================================


/* İNDEX OLUŞTURMA : 
	SQL Server'da indeksler, veritabanı motorunun verileri bulmak için tüm tabloyu taramak yerine, 
	bu özel olarak yapılandırılmış veri yapısını (genellikle B-tree yapısı) kullanarak istenen satırlara hızla erişmesini sağlar.
	Performans iyileştirmesi sağlamak ve sorguları hızlandırmak adına indexler oluşturuyoruz. Bu adım tablolar ve FK'ler başarılı 
	bir şekilde oluşturulduktan sonra gerçekleştirilir.
*/

--> kategori_id ile filtrelenen sorguları ve kategoriye göre yapılan JOIN leri hızlandırmak için;
CREATE INDEX IX_Urun_KategoriID ON Urun(kategori_id); 

--> satıcıya göre sorgulamalar ve satıcı-ürün JOIN’leri için;
CREATE INDEX IX_Urun_SaticiID ON Urun(satici_id);

--> bir müşterinin tüm siparişlerini hızlıca getirmek ve müşteri-sipariş JOIN lerini hızlandırmak için;
CREATE INDEX IX_Siparis_MusteriID ON Siparis(musteri_id);

--> herhangi bir siparişin detaylarını getiren sorgular için ;
CREATE INDEX IX_SiparisDetay_SiparisID ON Siparis_Detay(siparis_id);

--> bir ürünün hangi siparişlerde olduğunu veya stok hareketi/raporlamada kullanım ;
CREATE INDEX IX_SiparisDetay_Urun ON Siparis_Detay(urun_id);


PRINT 'Tüm tablolar, ilişkiler ve indexler başarıyla oluşturuldu.';

-- ============================================
-- C. VERİ EKLEME
-- ============================================

-- Kategoriler
INSERT INTO Kategori (ad) VALUES
	(N'Elektronik'),
	(N'Moda'),
	(N'Ev & Yaşam'),
	(N'Kitap'),
	(N'Kozmetik'),
	(N'Spor');
GO

-- Satıcılar
INSERT INTO Satici (ad, adres) VALUES
	(N'TechNova', N'İstanbul, Türkiye'),
	(N'StyleHub', N'İzmir, Türkiye'),
	(N'HomeLine', N'Bursa, Türkiye'),
	(N'BookWorld', N'Ankara, Türkiye'),
	(N'FitLife', N'Antalya, Türkiye'),
	(N'GadgetsTR', N'İstanbul, Türkiye'),
	(N'BeautyCorner', N'İstanbul, Türkiye'),
	(N'SportZone', N'İzmir, Türkiye');
GO

-- Müşteriler
INSERT INTO Musteri (ad, soyad, email, sehir, kayit_tarihi) VALUES
	(N'Ayşe', N'Yılmaz', N'ayse.yilmaz@example.com', N'İstanbul', '2023-01-15'),
	(N'Mehmet', N'Demir', N'mehmet.demir@example.com', N'Ankara', '2022-11-02'),
	(N'Elif', N'Kaya', N'elif.kaya@example.com', N'İzmir', '2023-02-10'),
	(N'Can', N'Öztürk', N'can.ozturk@example.com', N'Bursa', '2022-08-25'),
	(N'Zeynep', N'Güneş', N'zeynep.gunes@example.com', N'Antalya', '2023-03-05'),
	(N'Ozan', N'Kurt', N'ozan.kurt@example.com', N'İstanbul', '2023-04-18'),
	(N'Selin', N'Yalçın', N'selin.yalcin@example.com', N'Eskişehir', '2023-05-22'),
	(N'Burak', N'Arslan', N'burak.arslan@example.com', N'Gaziantep', '2023-06-11'),
	(N'Leyla', N'Çetin', N'leyla.cetin@example.com', N'Denizli', '2023-07-01'),
	(N'Emre', N'Polat', N'emre.polat@example.com', N'İzmir', '2023-08-09'),
	(N'Aylin', N'Koç', N'aylin.koc@example.com', N'Ankara', '2023-09-12'),
	(N'Kadir', N'Yıldız', N'kadir.yildiz@example.com', N'İstanbul', '2023-10-04'),
	(N'Deniz', N'Arı', N'deniz.ari@example.com', N'Bursa', '2023-10-20'),
	(N'Sinem', N'Taş', N'sinem.tas@example.com', N'Adana', '2023-11-05'),
	(N'Furkan', N'Çelik', N'furkan.celik@example.com', N'Konya', '2024-01-14'),
	(N'Gül', N'Ak', N'gul.ak@example.com', N'İzmir', '2024-02-02'),
	(N'Hakan', N'Yavuz', N'hakan.yavuz@example.com', N'Antalya', '2024-03-21'),
	(N'Pelin', N'Duran', N'pelin.duran@example.com', N'Kocaeli', '2024-04-10'),
	(N'Tolga', N'Öz', N'tolga.oz@example.com', N'Ordu', '2024-05-06'),
	(N'Nil', N'Berk', N'nil.berk@example.com', N'Sakarya', '2024-06-01');
GO

-- Ürünler
INSERT INTO Urun (ad, fiyat, stok, kategori_id, satici_id) VALUES
-- Elektronik
	(N'Smartphone X200', 9500.00, 50, 1, 1),
	(N'Laptop AirLite 13', 14500.00, 35, 1, 1),
	(N'Wireless Earbuds Flow', 750.00, 120, 1, 6),
	(N'Akıllı Saat Pulse+', 2999.00, 70, 1, 6),
	(N'Bluetooth Hoparlör Beat', 399.90, 90, 1, 6),

-- Moda
	(N'Denim Ceket Klasik', 1299.90, 80, 2, 2),
	(N'Spor Sweatshirt Urban', 349.90, 150, 2, 2),
	(N'Klasik Deri Ayakkabı', 899.50, 40, 2, 2),
	(N'Elbise Yazlık V1', 549.00, 70, 2, 2),

-- Ev & Yaşam
	(N'Seramik Yemek Takımı (12 parça)', 499.90, 40, 3, 3),
	(N'Çift Kişilik Yorgan', 799.00, 60, 3, 3),
	(N'Vakumlu Saklama Kabı Seti', 249.90, 100, 3, 3),

-- Kitap
	(N'Fantastik Roman: Kayıp Şehir', 89.90, 150, 4, 4),
	(N'Kişisel Gelişim: İlk Adım', 69.90, 200, 4, 4),
	(N'Çocuk Hikayeleri Seti', 129.90, 80, 4, 4),

-- Kozmetik
	(N'Nemlendirici Yüz Kremi 50ml', 199.90, 120, 5, 7),
	(N'Göz Makyaj Temizleyici', 99.90, 180, 5, 7),
	(N'Parfüm 50ml - Fresh', 349.90, 55, 5, 7),

-- Spor
	(N'Koşu Ayakkabısı FlexPro', 899.50, 60, 6, 8),
	(N'Spor Çanta Active', 299.90, 90, 6, 8),
	(N'Yoga Mat Comfort', 159.90, 130, 6, 8),

-- Ek Elektronik
	(N'Powerbank 20000mAh', 249.90, 200, 1, 6),
	(N'Gaming Mouse Pro', 429.90, 75, 1, 6),
	(N'Laptop Soğutucu Stand', 199.90, 110, 1, 6),
	(N'USB-C Çoklayıcı 4-port', 129.90, 160, 1, 6),
	(N'4K Monitör 27 inch', 4999.00, 25, 1, 1),
	(N'Kablosuz Klavye Set', 549.90, 80, 1, 6),
	(N'Mutfak Robotu 1000W', 1499.00, 45, 3, 3),
	(N'Bebek Bakım Seti', 399.00, 50, 3, 3),
	(N'Koşu Bandı Mini', 8999.00, 10, 6, 8);
GO

-- Siparişler
SET IDENTITY_INSERT Siparis ON;
GO
INSERT INTO Siparis (id, musteri_id, tarih, toplam_tutar, odeme_turu) VALUES
(1,  1,  '2024-01-12T10:35:00', 11000.00, N'Kredi Kartı'),   
(2,  2,  '2024-02-03T14:20:00', 17499.00, N'Havale'),        
(3,  3,  '2024-03-08T19:05:00', 2199.40, N'Kredi Kartı'),    
(4,  1,  '2024-03-15T09:10:00', 1048.90, N'Kredi Kartı'),    
(5,  5,  '2024-04-01T11:25:00', 1299.90, N'Kapıda Ödeme'),
(6,  6,  '2024-04-15T16:40:00', 299.90, N'Kredi Kartı'),
(7,  3,  '2024-05-02T12:30:00', 2547.00, N'Kredi Kartı'),    
(8,  8,  '2024-05-10T08:50:00', 899.50, N'Havale'),
(9,  9,  '2024-05-22T21:15:00', 179.80, N'Kredi Kartı'),
(10, 2,  '2024-06-01T18:00:00', 2999.00, N'Kredi Kartı'),    
(11, 11, '2024-06-05T13:05:00', 599.80, N'Kapıda Ödeme'),
(12, 12, '2024-06-10T10:10:00', 679.80, N'Kredi Kartı'),
(13, 13, '2024-06-20T15:45:00', 9398.00, N'Havale'),
(14, 1,  '2024-07-01T17:30:00', 199.90, N'Kredi Kartı'),     
(15, 3,  '2024-07-10T20:00:00', 419.70, N'Kredi Kartı');
GO
SET IDENTITY_INSERT Siparis OFF;
GO

-- Sipariş Detay
INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat) VALUES
-- Siparis 1
	(1, 1,  1, 9500.00),
	(1, 3,  2, 750.00),

-- Siparis 2
	(2, 2,  1, 14500.00), 
	(2, 4, 1, 2999.00),

-- Siparis 3
	(3, 6,  1, 1299.90), 
	(3, 8,  1, 899.50), 

-- Siparis 4
	(4, 11, 1, 799.00),
	(4, 12, 1, 249.90),

-- Siparis 5
	(5, 6,  1, 1299.90),

-- Siparis 6
	(6, 20, 1, 299.90),

-- Siparis 7
	(7, 29, 1, 1499.00),
	(7, 9,  2, 549.00),

-- Siparis 8
	(8, 8, 1, 899.50),

-- Siparis 9
	(9, 13, 2, 89.90),

-- Siparis 10
	(10, 9, 1, 2999.00),

-- Siparis 11
	(11, 21, 2, 299.90),

-- Siparis 12
	(12, 23, 1, 249.90),
	(12, 24, 1, 429.90),

-- Siparis 13
	(13, 28, 1, 399.00),
	(13, 30, 1, 8999.00),

-- Siparis 14
	(14, 17, 1, 199.90),

-- Siparis 15
	(15, 13, 1, 89.90),
	(15, 15, 1, 129.90),
	(15, 19, 1, 199.90);
GO

PRINT('Toplam eklenen satırlar:
		Kategori: 6
		Satici: 8
		Musteri: 20
		Urun: 30
		Siparis: 15
		Siparis_Detay: 30
	Toplam veri satırı sayısı: 109'
)




