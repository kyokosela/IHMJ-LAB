# Arma las hojas de sprites de Mayui (20 cuadros de 26x32 por capa, como Assets/Mayui/mayui_work_body.png) para cada ropa
# a partir de los .aseprite que dibujo tu artista (un cuadro quieto por direccion: front, right, left, back).
#
# Uso (desde la carpeta del proyecto):
#   powershell -ExecutionPolicy Bypass -File Tools\armar_hojas_mayui.ps1                 # escribe en Assets\Mayui
#   powershell -ExecutionPolicy Bypass -File Tools\armar_hojas_mayui.ps1 -Salida C:\ruta  # prueba sin tocar el proyecto
#
# Orden de los 20 cuadros de cada hoja (el que usan las animaciones de Prefabs/Player/Player.tscn):
#   0 quieto de frente (RESET) | 1 quieto a la derecha | 2 quieto a la izquierda | 3 quieto de espaldas
#   4-7 frente: quieto, paso A, neutro, paso B | 8-11 derecha | 12-15 izquierda | 16-19 espaldas
# Aun no hay cuadros de caminar dibujados para estas ropas: el neutro es el quieto (igual que en la hoja del uniforme) y en los
# pasos A y B el cuerpo baja 1 pixel (es el mismo rebote de 1 px que tienen la cabeza, el pelo y los ojos) y las piernas quedan
# quietas. Cuando tu artista dibuje los pasos, se reemplazan esos cuadros (A y B de cada direccion) en la hoja.
#
# Que capas cambian: solo 'body' (camisa / toalla) y 'legs' (falda / piernas). Cara, ojos, pelo y accesorios son los mismos de
# siempre; la unica excepcion es el pelo de la toalla de espaldas (mojado, mas oscuro): mayui_hair_towel.png.
param(
	[string]$Docs = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Docs'),
	[string]$Mayui = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Assets\Mayui'),
	[string]$Salida = '',
	[switch]$SoloVerificar,
	[switch]$Forzar   # sobrescribe hojas que ya existen (BORRA los cuadros de caminar que haya dibujado tu artista)
)
if ($Salida -eq '') { $Salida = $Mayui }
# seguro: no pisar hojas ya existentes, porque pueden tener cuadros dibujados a mano
if (-not $SoloVerificar -and -not $Forzar -and (Test-Path -LiteralPath $Salida)) {
	$ya = @(Get-ChildItem -LiteralPath $Salida -File | Where-Object { $_.Name -match '^mayui_((home|towel|outfit1)_(body|legs)|hair_towel)\.png$' })
	if ($ya.Count -gt 0) {
		"NO se escribio nada: ya existen " + $ya.Count + " hojas en " + $Salida + ". Usa -Salida <otra carpeta> para probar, o -Forzar para sobrescribirlas."
		exit 1
	}
}

$cs = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Text;
using System.Drawing;
using System.Drawing.Imaging;

public class AseLayer { public string Name; public int Flags; public int Type; public int Opacity; public bool Visible { get { return (Flags & 1) != 0; } } }
public class AseCel { public int Layer; public int Frame; public int X; public int Y; public int W; public int H; public int Opacity; public int Type; public int LinkFrame; public byte[] Data; }
public class AseFile {
  public int Frames, W, H, Depth, TransparentIndex; public uint[] Palette = new uint[256];
  public List<AseLayer> Layers = new List<AseLayer>(); public List<AseCel> Cels = new List<AseCel>();

  static string ReadString(BinaryReader r) { int n = r.ReadUInt16(); return Encoding.UTF8.GetString(r.ReadBytes(n)); }

  public static AseFile Load(string path) {
    var a = new AseFile();
    using (var r = new BinaryReader(File.OpenRead(path))) {
      r.ReadUInt32(); int magic = r.ReadUInt16(); if (magic != 0xA5E0) throw new Exception("no es un archivo de Aseprite: " + path);
      a.Frames = r.ReadUInt16(); a.W = r.ReadUInt16(); a.H = r.ReadUInt16(); a.Depth = r.ReadUInt16();
      r.ReadUInt32(); r.ReadUInt16(); r.ReadUInt32(); r.ReadUInt32(); a.TransparentIndex = r.ReadByte(); r.ReadBytes(3); r.ReadUInt16(); r.ReadBytes(2); r.ReadInt16(); r.ReadInt16(); r.ReadUInt16(); r.ReadUInt16(); r.ReadBytes(84);
      for (int f = 0; f < a.Frames; f++) {
        long frameStart = r.BaseStream.Position;
        uint bytes = r.ReadUInt32(); int fm = r.ReadUInt16(); if (fm != 0xF1FA) throw new Exception("cuadro corrupto");
        int oldChunks = r.ReadUInt16(); r.ReadUInt16(); r.ReadBytes(2); uint newChunks = r.ReadUInt32();
        uint chunks = (newChunks != 0) ? newChunks : (uint)oldChunks;
        for (uint c = 0; c < chunks; c++) {
          long chunkStart = r.BaseStream.Position; uint size = r.ReadUInt32(); int type = r.ReadUInt16();
          long end = chunkStart + size;
          if (type == 0x2004) {
            var l = new AseLayer(); l.Flags = r.ReadUInt16(); l.Type = r.ReadUInt16(); r.ReadUInt16(); r.ReadUInt16(); r.ReadUInt16(); r.ReadUInt16(); l.Opacity = r.ReadByte(); r.ReadBytes(3); l.Name = ReadString(r); a.Layers.Add(l);
          } else if (type == 0x2005) {
            var ce = new AseCel(); ce.Frame = f; ce.Layer = r.ReadUInt16(); ce.X = r.ReadInt16(); ce.Y = r.ReadInt16(); ce.Opacity = r.ReadByte(); ce.Type = r.ReadUInt16(); r.ReadInt16(); r.ReadBytes(5);
            if (ce.Type == 0) { ce.W = r.ReadUInt16(); ce.H = r.ReadUInt16(); ce.Data = r.ReadBytes(ce.W * ce.H * (a.Depth / 8)); }
            else if (ce.Type == 1) { ce.LinkFrame = r.ReadUInt16(); }
            else if (ce.Type == 2) {
              ce.W = r.ReadUInt16(); ce.H = r.ReadUInt16(); byte[] comp = r.ReadBytes((int)(end - r.BaseStream.Position));
              using (var ms = new MemoryStream(comp, 2, comp.Length - 2)) using (var ds = new DeflateStream(ms, CompressionMode.Decompress)) using (var o = new MemoryStream()) { ds.CopyTo(o); ce.Data = o.ToArray(); }
            }
            a.Cels.Add(ce);
          } else if (type == 0x2019) {
            uint n = r.ReadUInt32(); uint first = r.ReadUInt32(); uint last = r.ReadUInt32(); r.ReadBytes(8);
            for (uint i = first; i <= last; i++) { int fl = r.ReadUInt16(); int rr = r.ReadByte(), gg = r.ReadByte(), bb = r.ReadByte(), aa = r.ReadByte(); if (i < 256) a.Palette[i] = (uint)((aa << 24) | (rr << 16) | (gg << 8) | bb); if ((fl & 1) != 0) ReadString(r); }
          }
          r.BaseStream.Position = end;
        }
        r.BaseStream.Position = frameStart + bytes;
      }
    }
    return a;
  }

  uint PixelAt(AseCel c, int x, int y) {
    int bpp = Depth / 8; int o = (y * c.W + x) * bpp;
    if (Depth == 32) return (uint)((c.Data[o+3] << 24) | (c.Data[o] << 16) | (c.Data[o+1] << 8) | c.Data[o+2]);
    if (Depth == 16) { int v = c.Data[o]; int al = c.Data[o+1]; return (uint)((al << 24) | (v << 16) | (v << 8) | v); }
    int idx = c.Data[o]; if (idx == TransparentIndex) return 0; return Palette[idx] | 0xFF000000u;
  }

  public AseCel FindCel(int frame, int layer) {
    foreach (var c in Cels) if (c.Frame == frame && c.Layer == layer) { if (c.Type == 1) return FindCel(c.LinkFrame, layer); return c; }
    return null;
  }

  // Dibuja una capa (onlyLayer >= 0) o todas las visibles (-1) de un cuadro, en el orden del archivo (la primera es la de abajo)
  public Bitmap Render(int frame, int onlyLayer) {
    var bmp = new Bitmap(W, H, PixelFormat.Format32bppArgb);
    for (int li = 0; li < Layers.Count; li++) {
      if (onlyLayer >= 0 && li != onlyLayer) continue;
      if (onlyLayer < 0 && !Layers[li].Visible) continue;
      var c = FindCel(frame, li); if (c == null) continue;
      for (int y = 0; y < c.H; y++) for (int x = 0; x < c.W; x++) {
        int px = c.X + x, py = c.Y + y; if (px < 0 || py < 0 || px >= W || py >= H) continue;
        uint p = PixelAt(c, x, y); int al = (int)(p >> 24); if (al == 0) continue;
        al = al * c.Opacity / 255 * Layers[li].Opacity / 255; if (al == 0) continue;
        Color src = Color.FromArgb(al, (int)((p >> 16) & 255), (int)((p >> 8) & 255), (int)(p & 255));
        Color dst = bmp.GetPixel(px, py);
        if (dst.A == 0) { bmp.SetPixel(px, py, src); }
        else { double sa = src.A / 255.0, da = dst.A / 255.0; double oa = sa + da * (1 - sa);
          bmp.SetPixel(px, py, Color.FromArgb((int)(oa * 255), (int)((src.R * sa + dst.R * da * (1 - sa)) / oa), (int)((src.G * sa + dst.G * da * (1 - sa)) / oa), (int)((src.B * sa + dst.B * da * (1 - sa)) / oa))); }
      }
    }
    return bmp;
  }
}

public class Ropa { public string Id; public string Carpeta; public string[] Archivos; }

public static class HojasMayui {
  const int FW = 26, FH = 32, NF = 20;
  static readonly string[] DIRS = { "front", "right", "left", "back" };
  static readonly int[] QUIETO = { 4, 1, 2, 3 };   // cuadro 'quieto' de cada direccion (animaciones idle_down, idle_right, idle_left, idle_up)
  // direccion de cada uno de los 20 cuadros y si es un paso (A o B) de la caminata
  static readonly string[] DIR = { "front","right","left","back", "front","front","front","front", "right","right","right","right", "left","left","left","left", "back","back","back","back" };
  static readonly bool[] PASO = { false,false,false,false, false,true,false,true, false,true,false,true, false,true,false,true, false,true,false,true };
  static readonly string[] CUERPO = { "camisa", "camisaa", "toalla" };
  static readonly string[] PIERNAS = { "falda", "piernas", "pierna" };

  static int Capa(AseFile a, string[] nombres) {
    int r = -1;
    for (int i = 0; i < a.Layers.Count; i++) if (Array.IndexOf(nombres, a.Layers[i].Name.ToLowerInvariant()) >= 0 && a.FindCel(0, i) != null) r = i;
    return r;
  }

  static void Pegar(Bitmap hoja, Bitmap cuadro, int slot, int dy) {
    for (int y = 0; y < FH; y++) for (int x = 0; x < FW; x++) {
      Color c = cuadro.GetPixel(x, y); if (c.A == 0) continue;
      if (y + dy >= FH) continue;
      hoja.SetPixel(slot * FW + x, y + dy, c);
    }
  }

  static void Vaciar(Bitmap hoja, int slot) { for (int y = 0; y < FH; y++) for (int x = 0; x < FW; x++) hoja.SetPixel(slot * FW + x, y, Color.FromArgb(0, 0, 0, 0)); }

  static Bitmap Cargar(string ruta) { using (var tmp = new Bitmap(ruta)) { var b = new Bitmap(tmp.Width, tmp.Height, PixelFormat.Format32bppArgb); for (int y = 0; y < tmp.Height; y++) for (int x = 0; x < tmp.Width; x++) b.SetPixel(x, y, tmp.GetPixel(x, y)); return b; } }

  // Cuadro final del juego: capas en el orden de nodos de Player.tscn (legs, body, head, hair, eyes, accesories)
  static Bitmap ComponerJuego(Bitmap[] capas, int slot) {
    var o = new Bitmap(FW, FH, PixelFormat.Format32bppArgb);
    foreach (var h in capas) for (int y = 0; y < FH; y++) for (int x = 0; x < FW; x++) { Color c = h.GetPixel(slot * FW + x, y); if (c.A > 8) o.SetPixel(x, y, c); }
    return o;
  }

  public static string Armar(string docs, string dirMayui, string salida, bool escribir) {
    var sb = new StringBuilder();
    var ropas = new List<Ropa>();
    ropas.Add(new Ropa { Id = "home", Carpeta = "mayuipijama sprite", Archivos = new[] { "mayui pijama homeclothes front.aseprite", "mayui homeclothes right.aseprite", "mayui pijama homeclothes left.aseprite", "mayui homeclothes back.aseprite" } });
    ropas.Add(new Ropa { Id = "towel", Carpeta = "mayuitoalla sprite", Archivos = new[] { "mayui toalla front.aseprite", "mayui toalla right.aseprite", "mayui toalla left.aseprite", "mayui toalla back.aseprite" } });
    ropas.Add(new Ropa { Id = "outfit1", Carpeta = "mayui casual sprite\\mayui casual", Archivos = new[] { "mayui front casual.aseprite", "mayui casual right side.aseprite", "mayui casual left side.aseprite", "mayui casual back.aseprite" } });

    var face = Cargar(Path.Combine(dirMayui, "mayui_face.png"));
    var hair = Cargar(Path.Combine(dirMayui, "mayui_hair.png"));
    var eyes = Cargar(Path.Combine(dirMayui, "mayui_eyes.png"));
    var acc = Cargar(Path.Combine(dirMayui, "mayui_accesories.png"));
    if (!Directory.Exists(salida)) Directory.CreateDirectory(salida);

    foreach (var r in ropas) {
      var cuerpo = new Bitmap[4]; var piernas = new Bitmap[4]; var artista = new Bitmap[4]; var peloDir = new Bitmap[4];
      for (int d = 0; d < 4; d++) {
        string ruta = Path.Combine(docs, r.Carpeta, r.Archivos[d]);
        var a = AseFile.Load(ruta);
        if (a.W != FW || a.H != FH) throw new Exception(ruta + ": se esperaba 26x32 y mide " + a.W + "x" + a.H);
        int ic = Capa(a, CUERPO), ip = Capa(a, PIERNAS), ih = Capa(a, new[] { "pelo" });
        if (ic < 0 || ip < 0) throw new Exception(ruta + ": no encuentro la capa del cuerpo o de las piernas");
        cuerpo[d] = a.Render(0, ic); piernas[d] = a.Render(0, ip); artista[d] = a.Render(0, -1);
        peloDir[d] = ih >= 0 ? a.Render(0, ih) : null;
        // el juego dibuja el cuerpo ENCIMA de las piernas; si en el arte las piernas van encima, se le quita al cuerpo lo que ellas tapan
        int quitados = 0;
        if (ip > ic) for (int y = 0; y < FH; y++) for (int x = 0; x < FW; x++) if (piernas[d].GetPixel(x, y).A > 0 && cuerpo[d].GetPixel(x, y).A > 0) { cuerpo[d].SetPixel(x, y, Color.FromArgb(0, 0, 0, 0)); quitados++; }
        sb.AppendLine(string.Format("  {0,-6} {1,-5}: cuerpo='{2}' piernas='{3}'{4}", r.Id, DIRS[d], a.Layers[ic].Name, a.Layers[ip].Name, quitados > 0 ? ("  (piernas encima del cuerpo en el arte: " + quitados + " px quitados al cuerpo)") : ""));
      }
      var hojaCuerpo = new Bitmap(NF * FW, FH, PixelFormat.Format32bppArgb);
      var hojaPiernas = new Bitmap(NF * FW, FH, PixelFormat.Format32bppArgb);
      for (int s = 0; s < NF; s++) {
        int d = Array.IndexOf(DIRS, DIR[s]);
        Pegar(hojaCuerpo, cuerpo[d], s, PASO[s] ? 1 : 0);
        Pegar(hojaPiernas, piernas[d], s, 0);
      }
      // pelo: el mismo de siempre, salvo el de la toalla de espaldas (mojado, mas oscuro)
      var hojaPelo = hair;
      if (r.Id == "towel") {
        hojaPelo = new Bitmap(hair);
        for (int s = 0; s < NF; s++) if (DIR[s] == "back") { Vaciar(hojaPelo, s); Pegar(hojaPelo, peloDir[3], s, PASO[s] ? 1 : 0); }
        if (escribir) hojaPelo.Save(Path.Combine(salida, "mayui_hair_towel.png"), ImageFormat.Png);
      }
      if (escribir) {
        hojaCuerpo.Save(Path.Combine(salida, "mayui_" + r.Id + "_body.png"), ImageFormat.Png);
        hojaPiernas.Save(Path.Combine(salida, "mayui_" + r.Id + "_legs.png"), ImageFormat.Png);
      }
      // comprobacion: el cuadro quieto que se vera en el juego contra la composicion de tu artista
      var capasJuego = new Bitmap[] { hojaPiernas, hojaCuerpo, face, hojaPelo, eyes, acc };
      for (int d = 0; d < 4; d++) {
        var juego = ComponerJuego(capasJuego, QUIETO[d]);
        int dif = 0; var lista = new List<string>();
        for (int y = 0; y < FH; y++) for (int x = 0; x < FW; x++) {
          Color p = juego.GetPixel(x, y), q = artista[d].GetPixel(x, y);
          if (p.A < 9 && q.A < 9) continue;
          if (Math.Abs(p.A - q.A) > 24 || Math.Abs(p.R - q.R) + Math.Abs(p.G - q.G) + Math.Abs(p.B - q.B) > 12) { dif++; if (lista.Count < 6) lista.Add("(" + x + "," + y + ")"); }
        }
        sb.AppendLine(string.Format("  COMPROBACION {0,-6} {1,-5}: el juego se ve distinto al arte en {2} px {3}", r.Id, DIRS[d], dif, dif > 0 ? string.Join(" ", lista) : ""));
        juego.Dispose();
      }
    }
    return sb.ToString();
  }
}
'@

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition $cs -Language CSharp
$reporte = [HojasMayui]::Armar($Docs, $Mayui, $Salida, (-not $SoloVerificar))
$reporte
if (-not $SoloVerificar) { 'Hojas escritas en: ' + $Salida }
