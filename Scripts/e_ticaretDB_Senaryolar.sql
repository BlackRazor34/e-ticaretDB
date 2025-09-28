
-- C. VERÝ SORGULAMA VE RAPORLAMA

-- ==============================
-- En çok sipariþ veren 5 müþteri
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
-- En çok satýlan ürünler
-- ======================

SELECT
    u.ad AS UrunAdi,
    SUM(sd.adet) AS ToplamSatisMiktari,
    u.fiyat AS BirimFiyat,
    u.stok AS MevcutStok,
    k.ad AS Kategori,
    s.ad AS Satýcý
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
-- En yüksek cirosu olan satýcýlar
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
-- Aggregate & Group By Operasyonlarý
-- ====================================

-- =============================
-- Þehirlere göre müþteri sayýsý
-- =============================

SELECT 
    sehir,
    COUNT(*) as musteri_sayisi
FROM Musteri
GROUP BY sehir
ORDER BY COUNT(*) DESC;

-- ========================================
-- Kategori bazlý toplam satýþlar (cirolar)
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
-- Aylara göre sipariþ sayýsý
-- ==========================

SELECT
    YEAR(tarih) as yil,
    MONTH(tarih) as ay,
    COUNT(*) as siparis_sayisi
FROM Siparis
GROUP BY YEAR(tarih), MONTH(tarih)
ORDER BY YEAR(tarih), MONTH(tarih)

-- ================================================
-- Sipariþlerde müþteri bilgisi 
-- + ürün bilgisi
-- + satýcý bilgisi (her sipariþ detay satýrý için)
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
-- Hiç satýlmamýþ ürünler (satýþý olmayan ürünler)
-- VE
-- Satýlmayan Ürünlerin Stok Maliyeti EN YÜKSEKLER
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
-- Hiç sipariþ vermemiþ müþteriler
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
-- En çok kazanç saðlayan ilk 3 kategori
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
-- Ortalama sipariþ tutarýný geçen sipariþleri bul
-- ===============================================

-- CTE(Common Table Expression) WITH kullanýyouruz.
-- SQL WITH CTE içinde yazýlan sorguyu bir defa çalýþtýrýr, ihtiyaç olsaydý tekrar tekrar avg yazmadan kullanabilirdik.
-- avg_table ile sanal tablo oluþturup sonra CROSS JOIN ile baðlýyruz.
-- CTE : - Okunabilirlik - Tekrar Kuulaným - Performans/Optimizasyon saðlar.

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
-- En az bir kez elektronik ürün satýn alan müþteriler
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




