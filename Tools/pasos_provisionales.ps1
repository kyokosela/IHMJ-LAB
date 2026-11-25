# Pasos PROVISIONALES de las ropas que aun no tienen cuadros de caminar (casa, toalla y Outfit 1): los cuadros A y B de
# cada direccion se hacen a partir del cuadro quieto de tu artista. De frente y de espaldas se levanta un pie (como en el
# uniforme); de lado las piernas se abren en zancada. Cuando tu artista entregue los cuadros reales, se pegan encima en las
# mismas hojas (Assets/Mayui/mayui_<ropa>_legs.png). Repetible: siempre parte del cuadro quieto. Ver P54.
# Uso (desde la carpeta del proyecto): powershell -ExecutionPolicy Bypass -File Tools\pasos_provisionales.ps1
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$carpeta = Join-Path $PSScriptRoot '..\Assets\Mayui'
$W = 26; $H = 32
# direccion: cuadro quieto, paso A, paso B, y hacia donde avanza de lado (0 = de frente o de espaldas)
$DIRECCIONES = @(@(4, 5, 7, 0), @(8, 9, 11, 1), @(12, 13, 15, -1), @(16, 17, 19, 0))

function Get-Cuadro($hoja, $n) {
	$c = New-Object 'System.Drawing.Color[,]' $W, $H
	for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) { $c[$x, $y] = $hoja.GetPixel($n * $W + $x, $y) } }
	return , $c
}
function Set-Cuadro($hoja, $n, $c) {
	for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) { $p = $c[$x, $y]; $hoja.SetPixel(($n * $W + $x), $y, $p) } }
}
function Get-Limites($c) {
	$minX = $W; $maxX = -1; $minY = $H; $maxY = -1
	for ($y = 0; $y -lt $H; $y++) { for ($x = 0; $x -lt $W; $x++) { if ($c[$x, $y].A -gt 8) {
		if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }; if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y } } } }
	return @($minX, $maxX, $minY, $maxY)
}
# De frente o de espaldas: el pie de un lado sube 2 pixeles.
function New-PieArriba($quieto, $izquierdo) {
	$l = Get-Limites $quieto; $medio = ($l[0] + $l[1] + 1) / 2.0; $fondo = $l[3]
	$r = $quieto.Clone()
	for ($y = $fondo - 5; $y -le $fondo; $y++) { for ($x = 0; $x -lt $W; $x++) {
		if (($x -lt $medio) -ne $izquierdo) { continue }
		$r[$x, $y] = if ($y + 2 -le $fondo) { $quieto[$x, ($y + 2)] } else { [System.Drawing.Color]::Transparent } } }
	return , $r
}
# De lado: desde la cadera, la pierna de atras y la de delante se separan hasta 3 pixeles en los pies; una mas oscura.
function New-Zancada($quieto, $adelante, $oscuraDelante) {
	$l = Get-Limites $quieto; $fondo = $l[3]; $cadera = $fondo - 7
	$r = $quieto.Clone()
	for ($y = $cadera + 1; $y -le $fondo; $y++) { for ($x = 0; $x -lt $W; $x++) { $r[$x, $y] = [System.Drawing.Color]::Transparent } }
	foreach ($pierna in @(@(-1, (-not $oscuraDelante)), @(1, [bool]$oscuraDelante))) {
		$sentido = $pierna[0]; $oscura = $pierna[1]
		for ($y = $cadera + 1; $y -le $fondo; $y++) {
			$dx = [int][Math]::Round(3.0 * ($y - $cadera) / ($fondo - $cadera)) * $sentido * $adelante
			for ($x = 0; $x -lt $W; $x++) {
				$p = $quieto[$x, $y]
				if ($p.A -le 8 -or ($x + $dx) -lt 0 -or ($x + $dx) -ge $W) { continue }
				if ($oscura) { $p = [System.Drawing.Color]::FromArgb($p.A, [int]($p.R * 0.76), [int]($p.G * 0.72), [int]($p.B * 0.72)) }
				$r[($x + $dx), $y] = $p
			}
		}
	}
	return , $r
}

foreach ($ropa in 'home', 'towel', 'outfit1') {
	$ruta = Join-Path $carpeta "mayui_${ropa}_legs.png"
	$original = [System.Drawing.Image]::FromFile((Resolve-Path $ruta))
	$hoja = New-Object System.Drawing.Bitmap $original
	$original.Dispose()
	foreach ($d in $DIRECCIONES) {
		$quieto = Get-Cuadro $hoja $d[0]
		if ($d[3] -eq 0) {
			Set-Cuadro $hoja $d[1] (New-PieArriba $quieto $true)
			Set-Cuadro $hoja $d[2] (New-PieArriba $quieto $false)
		} else {
			Set-Cuadro $hoja $d[1] (New-Zancada $quieto $d[3] $false)
			Set-Cuadro $hoja $d[2] (New-Zancada $quieto $d[3] $true)
		}
	}
	$hoja.Save($ruta, [System.Drawing.Imaging.ImageFormat]::Png)
	$hoja.Dispose()
	"ok $ruta"
}
