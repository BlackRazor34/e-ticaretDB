/*
--------------------------------------------------------------------------
    E-T�CARET PLATFORMU S�M�LASYONU: INSERT, UPDATE, DELETE, TRUNCATE
--------------------------------------------------------------------------
Bu script, e_ticaretDB veritaban�nda ger�ekle�en g�nl�k i�lemleri,
veri b�t�nl���n� sa�layacak �ekilde ad�m ad�m sim�le eder.
--------------------------------------------------------------------------
*/

USE e_ticaretDB;
GO

-- =================================================================================
-- SENARYO 1 & 2: YEN� S�PAR�� OLU�TURMA VE STOK G�NCELLEME (TEK BLOK)
-- =================================================================================

PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 1: Yeni m��teri kayd� ve sipari� olu�turma';

-- De�i�kenleri tan�ml�yoruz. Bu de�i�kenler bir sonraki GO komutuna kadar ya�ayacak.
DECLARE @YeniMusteriID INT;
DECLARE @YeniSiparisID INT;
DECLARE @SiparisTutari DECIMAL(12, 2);

-- Birbirine ba�l� i�lemlerde veri tutarl�l���n� sa�lamak i�in TRANSACTION ba�lat�yoruz.
BEGIN TRANSACTION;

BEGIN TRY
    -- 1. ADIM: Yeni m��teri ekleniyor (INSERT)
    INSERT INTO Musteri (ad, soyad, email, sehir)
    VALUES (N'�mran', N'Ak', N'umran.ak@example.com', N'Mu�');

    -- Eklenen m��terinin ID'sini al�yoruz.
    SET @YeniMusteriID = SCOPE_IDENTITY();
    PRINT 'Yeni m��teri eklendi. M��teri ID: ' + CAST(@YeniMusteriID AS VARCHAR);

    -- 2. ADIM: Sipari� tutar�n� hesapl�yoruz
    SELECT @SiparisTutari = SUM(fiyat) FROM Urun WHERE id IN (3, 23);

    -- 3. ADIM: Sipari�in ana kayd�n� olu�turuyoruz (INSERT)
    INSERT INTO Siparis (musteri_id, toplam_tutar, odeme_turu)
    VALUES (@YeniMusteriID, @SiparisTutari, N'Kredi Kart�');

    -- Olu�turulan sipari�in ID'sini al�yoruz
    SET @YeniSiparisID = SCOPE_IDENTITY();
    PRINT 'Ana sipari� kayd� olu�turuldu. Sipari� ID: ' + CAST(@YeniSiparisID AS VARCHAR);

    -- 4. ADIM: Sipari�in detaylar�n� ekliyoruz (INSERT)
    INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat)
    VALUES
        (@YeniSiparisID, 3, 1, (SELECT fiyat FROM Urun WHERE id = 3)),
        (@YeniSiparisID, 23, 1, (SELECT fiyat FROM Urun WHERE id = 23));
    PRINT 'Sipari� detaylar� eklendi.';

    -- Buraya kadar hi�bir hata olmad�ysa, t�m i�lemleri onayl�yoruz.
    COMMIT TRANSACTION;
    PRINT 'TRANSACTION ba�ar�l�: Yeni m��teri ve sipari�i kal�c� olarak kaydedildi.';

END TRY
BEGIN CATCH
    -- Herhangi bir ad�mda hata olursa, t�m i�lemleri geri al�yoruz.
    ROLLBACK TRANSACTION;
    PRINT 'HATA: Bir sorun olu�tu, t�m i�lemler geri al�nd�. Veritaban� eski halinde.';
END CATCH;

-- SENARYO 2'yi ayn� blok i�inde �al��t�r�yoruz
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 2: Stoklar� g�ncelleme';

-- @YeniSiparisID de�i�keni hala haf�zada oldu�u i�in bu komut sorunsuz �al��acakt�r.
UPDATE Urun
SET stok = stok - SD.adet
FROM Urun
JOIN Siparis_Detay SD ON Urun.id = SD.urun_id
WHERE SD.siparis_id = @YeniSiparisID;

PRINT 'Stoklar ba�ar�yla g�ncellendi. Kontrol ediliyor:';
SELECT id, ad, stok FROM Urun WHERE id IN (3, 23);
GO -- Senaryo 1 ve 2'nin toplu i�i burada bitiyor.


-- =================================================================================
-- SENARYO 3: SATI�TAN KALDIRILAN B�R �R�N� S�LME (DELETE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 3: Sat��tan kald�r�lan bir �r�n� silme';

PRINT 'Silme �ncesi �r�n kontrol� (ID=25):';
SELECT id, ad FROM Urun WHERE id = 25;

DELETE FROM Urun WHERE id = 25;

PRINT '�r�n (ID=25) ba�ar�yla silindi. Silme sonras� kontrol:';
SELECT id, ad FROM Urun WHERE id = 25;
GO


-- =================================================================================
-- SENARYO 4: M��TER� HESABINI S�LME (DELETE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 4: Bir m��teri hesab�n� silme';

PRINT 'Silme �ncesi m��teri kontrol� (ID=20):';
SELECT id, ad, soyad FROM Musteri WHERE id = 20;

DELETE FROM Musteri WHERE id = 20;

PRINT 'M��teri (ID=20) ba�ar�yla silindi. Silme sonras� kontrol:';
SELECT id, ad, soyad FROM Musteri WHERE id = 20;
GO


-- =================================================================================
-- SENARYO 5: KATEGOR� BAZLI TOPLU F�YAT G�NCELLEME (UPDATE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 5: Kategoriye g�re toplu fiyat g�ncelleme';

PRINT 'G�ncelleme �ncesi "Moda" kategorisi fiyatlar�:';
SELECT ad, fiyat FROM Urun WHERE kategori_id = 2;

UPDATE Urun SET fiyat = fiyat * 1.10 WHERE kategori_id = 2;

PRINT 'Fiyatlar g�ncellendi. G�ncelleme sonras� "Moda" kategorisi fiyatlar�:';
SELECT ad, fiyat FROM Urun WHERE kategori_id = 2;
GO


-- =================================================================================
-- SENARYO 6: GE��C� RAPOR TABLOSUNU TEM�ZLEME (TRUNCATE)
-- =================================================================================
PRINT '--------------------------------------------------------------------------';
PRINT 'Senaryo 6: Ge�ici bir rapor tablosunu TRUNCATE ile s�f�rlama';

CREATE TABLE Gecici_Satis_Raporu (urun_adi NVARCHAR(100), toplam_adet INT);

INSERT INTO Gecici_Satis_Raporu (urun_adi, toplam_adet)
SELECT U.ad, SUM(SD.adet) FROM Siparis_Detay SD JOIN Urun U ON SD.urun_id = U.id GROUP BY U.ad;

PRINT 'Ge�ici rapor tablosu dolduruldu. ��erik:';
SELECT * FROM Gecici_Satis_Raporu;

TRUNCATE TABLE Gecici_Satis_Raporu;
PRINT 'Ge�ici rapor tablosu TRUNCATE edildi. ��erik kontrol�:';
SELECT * FROM Gecici_Satis_Raporu;

DROP TABLE Gecici_Satis_Raporu;
PRINT 'Ge�ici tablo DROP ile sistemden kald�r�ld�.';
GO

PRINT '--------------------------------------------------------------------------';
PRINT 'T�m senaryolar ba�ar�yla tamamland�.';
GO