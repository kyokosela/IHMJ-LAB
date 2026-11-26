# Dibuja (PROVISIONAL) lo que se ve dentro de la olla abierta del fregadero, en el mismo lienzo 1900x1080 que el arte de la
# cocina: agua, ingredientes picados y comida casera. El arte real solo tiene que reemplazar los PNG con el mismo nombre.
# Uso (desde la carpeta del proyecto):  powershell -File Tools/contenido_olla_provisional.ps1
Add-Type -AssemblyName System.Drawing
$salida = Join-Path $PSScriptRoot '..\Assets\UI\Kitchen'

# Boca de la olla por dentro de su linea negra (medida sobre pot_open.png): borde de atras (izquierda a derecha) y de delante.
$atras = @(@(813, 692.5), @(820, 689), @(830, 684), @(840, 679.5), @(850, 675.5), @(860, 672.3), @(870, 670), @(880, 668),
	@(890, 666.5), @(900, 665.3), @(910, 664.3), @(920, 663.8), @(930, 663.8), @(938, 664.3), @(944, 665.8), @(948.5, 668))
$delante = @(@(946, 670), @(940, 672.8), @(930, 676), @(920, 678.7), @(910, 681), @(900, 683), @(890, 685), @(880, 687),
	@(870, 689), @(860, 690.5), @(850, 691.8), @(840, 692.5), @(830, 693), @(820, 692.8), @(815, 692.8))

function Get-Puntos($lista) { [System.Drawing.PointF[]]@($lista | ForEach-Object { New-Object System.Drawing.PointF ([single]$_[0]), ([single]$_[1]) }) }
function Get-Color($r, $g, $b, $a = 255) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }

# Superficie del contenido: el borde de atras bajado un poco (se ve algo de la pared de la olla por encima).
$superficie = @($atras | ForEach-Object { $t = ($_[0] - 813) / 135.5; , @($_[0], ($_[1] + 5 * [math]::Sin([math]::PI * $t))) })

function New-Lienzo {
	$img = New-Object System.Drawing.Bitmap 1900, 1080, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
	$g = [System.Drawing.Graphics]::FromImage($img)
	$g.SmoothingMode = 'AntiAlias'
	$boca = New-Object System.Drawing.Drawing2D.GraphicsPath
	$boca.AddPolygon((Get-Puntos ($atras + $delante)))
	$g.SetClip($boca)
	return @($img, $g)
}

function Add-Liquido($g, $arriba, $abajo) {
	$relleno = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Point 0, 662), (New-Object System.Drawing.Point 0, 696), $arriba, $abajo
	$g.FillPolygon($relleno, (Get-Puntos ($superficie + $delante)))
	$g.DrawLines((New-Object System.Drawing.Pen (Get-Color 20 20 20 150), 1.2), (Get-Puntos $superficie))
}

function Add-Trozos($g, $colores, $cuantos, $semilla) {
	$azar = New-Object System.Random $semilla
	$borde = New-Object System.Drawing.Pen (Get-Color 35 25 20 220), 1.1
	for ($i = 0; $i -lt $cuantos; $i++) {
		$x = 818 + $azar.NextDouble() * 124
		# entre la superficie y el borde de delante a esa altura (la boca esta inclinada)
		$y = 692 - ($x - 815) * 0.19 - 3 - $azar.NextDouble() * 9
		$ancho = 8 + $azar.NextDouble() * 8
		$alto = $ancho * (0.45 + $azar.NextDouble() * 0.25)
		$brocha = New-Object System.Drawing.SolidBrush ($colores[$azar.Next($colores.Count)])
		$g.FillEllipse($brocha, [single]($x - $ancho / 2), [single]($y - $alto / 2), [single]$ancho, [single]$alto)
		$g.DrawEllipse($borde, [single]($x - $ancho / 2), [single]($y - $alto / 2), [single]$ancho, [single]$alto)
	}
}

function Save-Lienzo($par, $nombre) {
	$par[1].Dispose()
	$par[0].Save((Join-Path $salida $nombre), [System.Drawing.Imaging.ImageFormat]::Png)
	$par[0].Dispose()
	"  $nombre"
}

# Agua: los colores de tu dibujo del chorro (water.png), con un par de brillos.
$agua = New-Lienzo
Add-Liquido $agua[1] (Get-Color 0 188 205) (Get-Color 0 226 234)
$brillo = New-Object System.Drawing.SolidBrush (Get-Color 140 243 248)
$agua[1].FillEllipse($brillo, 905, 670, 20, 4)
$agua[1].FillEllipse($brillo, 852, 682, 9, 3)
Save-Lienzo $agua 'pot_content_water.png'

# Ingredientes picados: trozos crudos.
$crudo = New-Lienzo
Add-Liquido $crudo[1] (Get-Color 112 92 66) (Get-Color 142 118 84)
Add-Trozos $crudo[1] @((Get-Color 232 126 36), (Get-Color 104 170 60), (Get-Color 200 62 50), (Get-Color 232 205 140)) 46 7
Save-Lienzo $crudo 'pot_content_ingredients.png'

# Comida casera: un guiso.
$guiso = New-Lienzo
Add-Liquido $guiso[1] (Get-Color 150 76 28) (Get-Color 204 124 48)
Add-Trozos $guiso[1] @((Get-Color 214 150 70), (Get-Color 126 70 40), (Get-Color 118 132 54)) 20 11
$guiso[1].FillEllipse((New-Object System.Drawing.SolidBrush (Get-Color 246 190 110 200)), 898, 671, 18, 3)
Save-Lienzo $guiso 'pot_content_food.png'
