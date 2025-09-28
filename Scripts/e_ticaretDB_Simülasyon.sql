/*
--------------------------------------------------------------------------
    E-TÝCARET PLATFORMU SÝMÜLASYONU: INSERT, UPDATE, DELETE, TRUNCATE
--------------------------------------------------------------------------
Bu script, e_ticaretDB veritabanýnda gerçekleþen günlük iþlemleri,
veri bütünlüðünü saðlayacak þekilde adým adým simüle eder.
--------------------------------------------------------------------------
*/

USE e_ticaretDB;
GO

-- =================================================================================
-- SENARYO 1 & 2: YENÝ SÝPARÝÞ OLUÞTURMA VE STOK GÜNCELLEME (TEK BLOK)
-- =================================================================================

PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 1: Yeni müþteri kaydý ve sipariþ oluþturma';

-- Deðiþkenleri tanýmlýyoruz. Bu deðiþkenler bir sonraki GO komutuna kadar yaþayacak.
DECLARE @YeniMusteriID INT;
DECLARE @YeniSiparisID INT;
DECLARE @SiparisTutari DECIMAL(12, 2);

-- Birbirine baðlý iþlemlerde veri tutarlýlýðýný saðlamak için TRANSACTION baþlatýyoruz.
BEGIN TRANSACTION;

BEGIN TRY
    -- 1. ADIM: Yeni müþteri ekleniyor (INSERT)
    INSERT INTO Musteri (ad, soyad, email, sehir)
    VALUES (N'Ümran', N'Ak', N'umran.ak@example.com', N'Muþ');

    -- Eklenen müþterinin ID'sini alýyoruz.
    SET @YeniMusteriID = SCOPE_IDENTITY();
    PRINT 'Yeni müþteri eklendi. Müþteri ID: ' + CAST(@YeniMusteriID AS VARCHAR);

    -- 2. ADIM: Sipariþ tutarýný hesaplýyoruz
    SELECT @SiparisTutari = SUM(fiyat) FROM Urun WHERE id IN (3, 23);

    -- 3. ADIM: Sipariþin ana kaydýný oluþturuyoruz (INSERT)
    INSERT INTO Siparis (musteri_id, toplam_tutar, odeme_turu)
    VALUES (@YeniMusteriID, @SiparisTutari, N'Kredi Kartý');

    -- Oluþturulan sipariþin ID'sini alýyoruz
    SET @YeniSiparisID = SCOPE_IDENTITY();
    PRINT 'Ana sipariþ kaydý oluþturuldu. Sipariþ ID: ' + CAST(@YeniSiparisID AS VARCHAR);

    -- 4. ADIM: Sipariþin detaylarýný ekliyoruz (INSERT)
    INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat)
    VALUES
        (@YeniSiparisID, 3, 1, (SELECT fiyat FROM Urun WHERE id = 3)),
        (@YeniSiparisID, 23, 1, (SELECT fiyat FROM Urun WHERE id = 23));
    PRINT 'Sipariþ detaylarý eklendi.';

    -- Buraya kadar hiçbir hata olmadýysa, tüm iþlemleri onaylýyoruz.
    COMMIT TRANSACTION;
    PRINT 'TRANSACTION baþarýlý: Yeni müþteri ve sipariþi kalýcý olarak kaydedildi.';

END TRY
BEGIN CATCH
    -- Herhangi bir adýmda hata olursa, tüm iþlemleri geri alýyoruz.
    ROLLBACK TRANSACTION;
    PRINT 'HATA: Bir sorun oluþtu, tüm iþlemler geri alýndý. Veritabaný eski halinde.';
END CATCH;

-- SENARYO 2'yi ayný blok içinde çalýþtýrýyoruz
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 2: Stoklarý güncelleme';

-- @YeniSiparisID deðiþkeni hala hafýzada olduðu için bu komut sorunsuz çalýþacaktýr.
UPDATE Urun
SET stok = stok - SD.adet
FROM Urun
JOIN Siparis_Detay SD ON Urun.id = SD.urun_id
WHERE SD.siparis_id = @YeniSiparisID;

PRINT 'Stoklar baþarýyla güncellendi. Kontrol ediliyor:';
SELECT id, ad, stok FROM Urun WHERE id IN (3, 23);
GO -- Senaryo 1 ve 2'nin toplu iþi burada bitiyor.


-- =================================================================================
-- SENARYO 3: SATIÞTAN KALDIRILAN BÝR ÜRÜNÜ SÝLME (DELETE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 3: Satýþtan kaldýrýlan bir ürünü silme';

PRINT 'Silme öncesi ürün kontrolü (ID=25):';
SELECT id, ad FROM Urun WHERE id = 25;

DELETE FROM Urun WHERE id = 25;

PRINT 'Ürün (ID=25) baþarýyla silindi. Silme sonrasý kontrol:';
SELECT id, ad FROM Urun WHERE id = 25;
GO


-- =================================================================================
-- SENARYO 4: MÜÞTERÝ HESABINI SÝLME (DELETE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 4: Bir müþteri hesabýný silme';

PRINT 'Silme öncesi müþteri kontrolü (ID=20):';
SELECT id, ad, soyad FROM Musteri WHERE id = 20;

DELETE FROM Musteri WHERE id = 20;

PRINT 'Müþteri (ID=20) baþarýyla silindi. Silme sonrasý kontrol:';
SELECT id, ad, soyad FROM Musteri WHERE id = 20;
GO


-- =================================================================================
-- SENARYO 5: KATEGORÝ BAZLI TOPLU FÝYAT GÜNCELLEME (UPDATE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 5: Kategoriye göre toplu fiyat güncelleme';

PRINT 'Güncelleme öncesi "Moda" kategorisi fiyatlarý:';
SELECT ad, fiyat FROM Urun WHERE kategori_id = 2;

UPDATE Urun SET fiyat = fiyat * 1.10 WHERE kategori_id = 2;

PRINT 'Fiyatlar güncellendi. Güncelleme sonrasý "Moda" kategorisi fiyatlarý:';
SELECT ad, fiyat FROM Urun WHERE kategori_id = 2;
GO


-- =================================================================================
-- SENARYO 6: GEÇÝCÝ RAPOR TABLOSUNU TEMÝZLEME (TRUNCATE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 6: Geçici bir rapor tablosunu TRUNCATE ile sýfýrlama';

CREATE TABLE Gecici_Satis_Raporu (urun_adi NVARCHAR(100), toplam_adet INT);

INSERT INTO Gecici_Satis_Raporu (urun_adi, toplam_adet)
SELECT U.ad, SUM(SD.adet) FROM Siparis_Detay SD JOIN Urun U ON SD.urun_id = U.id GROUP BY U.ad;

PRINT 'Geçici rapor tablosu dolduruldu. Ýçerik:';
SELECT * FROM Gecici_Satis_Raporu;

TRUNCATE TABLE Gecici_Satis_Raporu;
PRINT 'Geçici rapor tablosu TRUNCATE edildi. Ýçerik kontrolü:';
SELECT * FROM Gecici_Satis_Raporu;

DROP TABLE Gecici_Satis_Raporu;
PRINT 'Geçici tablo DROP ile sistemden kaldýrýldý.';
GO

PRINT '--------------------------------------------------------------------------';
PRINT 'Tüm senaryolar baþarýyla tamamlandý.';
GO