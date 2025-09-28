
-- C. VER� SORGULAMA VE RAPORLAMA

-- ==============================
-- En �ok sipari� veren 5 m��teri
-- ==============================

SELECT TOP (5)
	M.id AS MusteriID,
	M.ad + N' ' + M.soyad AS MusteriAdi,
	COUNT(S.id) ToplamSiparisSayisi,
	SUM (S.toplam_tutar) AS ToplamHarcama
FROM 
	Musteri AS M
JOIN 
	Siparis AS S 
	ON M.id = S.musteri_id
GROUP BY
	M.id,
	M.ad,
	M.soyad
ORDER BY
	ToplamSiparisSayisi DESC,
	ToplamHarcama DESC

-- ======================
-- En �ok sat�lan �r�nler
-- ======================

SELECT
    u.ad AS UrunAdi,
    SUM(sd.adet) AS ToplamSatisMiktari,
    u.fiyat AS BirimFiyat,
    u.stok AS MevcutStok,
    k.ad AS Kategori,
    s.ad AS Sat�c�
FROM Siparis_Detay sd
JOIN Urun u ON sd.urun_id = u.id
JOIN Kategori k ON u.kategori_id = k.id
JOIN Satici s ON u.satici_id = s.id
GROUP BY
    u.id,
    u.ad,
    u.fiyat,
    u.stok,
    k.ad,
    s.ad
ORDER BY
    ToplamSatisMiktari DESC

-- ===============================
-- En y�ksek cirosu olan sat�c�lar
-- ===============================

SELECT TOP 10
    satici.ad,
    SUM(sd.fiyat * sd.adet) AS toplam_ciro
FROM Satici satici
JOIN Urun u 
ON u.satici_id = satici.id
JOIN Siparis_Detay sd 
ON sd.urun_id = u.id
GROUP BY satici.id, satici.ad
ORDER BY SUM(sd.fiyat * sd.adet) DESC;

-- ====================================
-- Aggregate & Group By Operasyonlar�
-- ====================================

-- =============================
-- �ehirlere g�re m��teri say�s�
-- =============================

SELECT 
    sehir,
    COUNT(*) as musteri_sayisi
FROM Musteri
GROUP BY sehir
ORDER BY COUNT(*) DESC;

-- ========================================
-- Kategori bazl� toplam sat��lar (cirolar)
-- ========================================

SELECT
    k.id,
    k.ad as kategori,
    SUM (sd.fiyat * sd.adet) as kategori_toplam_ciro
FROM Kategori k
JOIN Urun u ON u.kategori_id = k.id
LEFT JOIN Siparis_Detay sd ON sd.urun_id = u.id
GROUP BY k.id, k.ad
ORDER BY SUM(sd.fiyat * sd.adet) DESC;

-- ==========================
-- Aylara g�re sipari� say�s�
-- ==========================

SELECT
    YEAR(tarih) as yil,
    MONTH(tarih) as ay,
    COUNT(*) as siparis_sayisi
FROM Siparis
GROUP BY YEAR(tarih), MONTH(tarih)
ORDER BY YEAR(tarih), MONTH(tarih)

-- ================================================
-- Sipari�lerde m��teri bilgisi 
-- + �r�n bilgisi
-- + sat�c� bilgisi (her sipari� detay sat�r� i�in)
-- ================================================

SELECT
    m.ad + ' ' + m.soyad AS musteri_adi_soyadi,
    u.ad AS urun_adi,
    sat.ad AS satici_adi,
    sd.adet,
    sd.fiyat AS birim_fiyat,
    s.toplam_tutar,
    s.odeme_turu
FROM Siparis s
JOIN Musteri m 
    ON m.id = s.musteri_id
JOIN Siparis_Detay sd 
    ON sd.siparis_id = s.id
JOIN Urun u 
    ON u.id = sd.urun_id
JOIN Satici sat 
    ON sat.id = u.satici_id
ORDER BY s.id, sd.id;

-- ================================================
-- Hi� sat�lmam�� �r�nler (sat��� olmayan �r�nler)
-- VE
-- Sat�lmayan �r�nlerin Stok Maliyeti EN Y�KSEKLER
-- ================================================

SELECT
    u.ad,
    u.fiyat,
    u.stok,
    SUM(u.fiyat * u.stok) as Toplam_Stok_Maliyeti
FROM Urun u
LEFT JOIN Siparis_Detay sd 
    ON sd.urun_id = u.id
WHERE sd.urun_id IS NULL
GROUP BY u.id, u.ad, u.fiyat, u.stok
ORDER BY SUM(u.fiyat * u.stok) DESC;

-- ===============================
-- Hi� sipari� vermemi� m��teriler
-- ===============================

SELECT
    m.ad,
    m.soyad,
    m.email,
    m.sehir,
    FORMAT(m.kayit_tarihi, 'MM-yyyy') as kayit_tarihi
FROM Musteri m
LEFT JOIN Siparis s ON s.musteri_id = m.id
WHERE s.id IS NULL;


-- =====================================
-- En �ok kazan� sa�layan ilk 3 kategori
-- =====================================

SELECT TOP 3
    k.ad as Kategori_Adi,
    SUM(sd.fiyat * sd.adet) AS kategoriye_gore_ciro_tl
FROM Kategori k
JOIN Urun u 
    ON u.kategori_id = k.id
JOIN Siparis_Detay sd 
    ON sd.urun_id = u.id
GROUP BY k.id, k.ad
ORDER BY SUM(sd.fiyat * sd.adet) DESC;


-- ===============================================
-- Ortalama sipari� tutar�n� ge�en sipari�leri bul
-- ===============================================

-- CTE(Common Table Expression) WITH kullan�youruz.
-- SQL WITH CTE i�inde yaz�lan sorguyu bir defa �al��t�r�r, ihtiya� olsayd� tekrar tekrar avg yazmadan kullanabilirdik.
-- avg_table ile sanal tablo olu�turup sonra CROSS JOIN ile ba�l�yruz.
-- CTE : - Okunabilirlik - Tekrar Kuulan�m - Performans/Optimizasyon sa�lar.

;WITH avg_table AS (
    SELECT AVG(CAST(toplam_tutar AS DECIMAL(18,2))) AS ortalama_tutar
    FROM Siparis
)
SELECT
    m.ad + ' ' + m.soyad AS musteri,
    u.ad AS urun_adi,
    sd.adet,
    FORMAT(s.tarih, 'MM-yyyy HH:mm') AS siparis_tarihi,
    sd.fiyat AS birim_fiyat,
    s.toplam_tutar
FROM Siparis s
JOIN Musteri m 
    ON m.id = s.musteri_id
JOIN Siparis_Detay sd 
    ON sd.siparis_id = s.id
JOIN Urun u 
    ON u.id = sd.urun_id
CROSS JOIN avg_table a
WHERE s.toplam_tutar > a.ortalama_tutar
ORDER BY s.toplam_tutar DESC, s.id, u.ad;



-- ===========================================================================
-- En az bir kez elektronik �r�n sat�n alan m��teriler
-- ===========================================================================

SELECT DISTINCT
    m.ad,
    m.soyad,
    m.email
FROM Musteri m
JOIN Siparis s 
    ON s.musteri_id = m.id
JOIN Siparis_Detay sd 
    ON sd.siparis_id = s.id
JOIN Urun u 
    ON u.id = sd.urun_id
JOIN Kategori k 
    ON k.id = u.kategori_id
WHERE k.ad = N'Elektronik';




