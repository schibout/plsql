# =====================================================================
#  Generation du rapport HTML - Controle Folio Rose
# =====================================================================
#  Ce fichier ne fait que definir New-RapportHtml. Il est charge par
#  point-source depuis Verifier_Factures.ps1 (production) et depuis
#  Apercu_Rapport.ps1 (re-affichage d'un controle deja realise).
#  Les deux passent ainsi par exactement le meme code de rendu.
#
#  IMPORTANT - ENCODAGE : garder ce fichier en UTF-8 AVEC BOM.
# =====================================================================

function ConvertTo-NombreRapport {
    param([string]$Valeur)
    if ([string]::IsNullOrWhiteSpace($Valeur)) { return [double]0 }
    $v = $Valeur.Trim().Replace(' ', '').Replace([string][char]160, '').Replace(',', '.')
    if ($v -eq '-' -or $v -eq '') { return [double]0 }
    $d = [double]0
    if ([double]::TryParse($v, [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return $d }
    return [double]0
}

function ConvertTo-HtmlTexte {
    param([string]$T)
    if ([string]::IsNullOrEmpty($T)) { return '' }
    return $T.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

function Format-MontantRapport {
    param($V)
    return ('{0:N2}' -f [double]$V)
}

function New-RapportHtml {
    param(
        [Parameter(Mandatory = $true)] $Resultats,      # objets du rapport (memes colonnes que le CSV)
        [Parameter(Mandatory = $true)] [string] $CheminHtml,
        [string] $FichierSource    = '',
        [string] $Encodage         = '',
        [string] $Base             = '',
        [int]    $NbInterrogations = 0,
        [double] $Duree            = 0,
        [string] $CheminCsv        = ''
    )

    $lignes = @($Resultats)
    $auj    = (Get-Date).Date

    # Enrichissement : montants numeriques et anciennete de l'ecart.
    # L'age est la donnee qui manquait le plus : un ecart de la veille et
    # un ecart d'il y a un mois n'appellent pas la meme reaction.
    $enrichi = @(foreach ($r in $lignes) {
        $dt  = $null
        $tmp = [datetime]::MinValue
        if ([datetime]::TryParseExact([string]$r.'Date', 'dd/MM/yyyy',
                [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$tmp)) {
            $dt = $tmp
        }
        $nbOra = ConvertTo-NombreRapport ([string]$r.'Nb Pieces OA')
        $mtOra = ConvertTo-NombreRapport ([string]$r.'Montant OA ')
        $mtInt = ConvertTo-NombreRapport ([string]$r.'Montant Interface OA')

        [PSCustomObject]@{
            Folio       = [string]$r.'Folio'
            Type        = [string]$r.'Type'
            DateTxt     = [string]$r.'Date'
            Age         = if ($dt) { [int]($auj - $dt.Date).TotalDays } else { $null }
            Fichier     = [string]$r.'Nom fichier transmis'
            EcartNbDecl = ConvertTo-NombreRapport ([string]$r.'Ecarts Nb Piece')
            EcartDbDecl = ConvertTo-NombreRapport ([string]$r.'Ecarts Débit')
            NbOra       = $nbOra
            MtOra       = $mtOra
            MtInterface = $mtInt
            EcartNbCalc = ConvertTo-NombreRapport ([string]$r.'Ecart Nb Piece Calcule')
            EcartMtCalc = ConvertTo-NombreRapport ([string]$r.'Ecart Mt Calcule')
            Commentaire = [string]$r.'Commentaire'
            Statut      = [string]$r.'Statut Verification'
            # Rien nulle part : le flux n'est jamais arrive.
            OraVide     = ($nbOra -eq 0 -and $mtOra -eq 0 -and $mtInt -eq 0)
            # Present en interface mais absent des tables definitives :
            # le fichier a bien ete recu, l'integration n'a pas eu lieu.
            # C'est le cas le plus frequent en pratique, et il appelle une
            # action tres differente d'un simple ecart de montant.
            EnInterface = ($mtOra -eq 0 -and $mtInt -ne 0)
        }
    })

    $nbOk    = @($enrichi | Where-Object { $_.Statut -eq 'OK' }).Count
    $nbKo    = @($enrichi | Where-Object { $_.Statut -eq 'KO' }).Count
    $nbIndet = @($enrichi | Where-Object { $_.Statut -eq 'INDETERMINE' }).Count
    $nbVides = @($enrichi | Where-Object { $_.OraVide }).Count
    $nbInter = @($enrichi | Where-Object { $_.EnInterface }).Count

    $montantEnEcart = ($enrichi | Where-Object { $_.Statut -ne 'OK' } |
                       Measure-Object -Property EcartMtCalc -Sum).Sum
    if ($null -eq $montantEnEcart) { $montantEnEcart = 0 }
    $ageMax = ($enrichi | Where-Object { $null -ne $_.Age } | Measure-Object -Property Age -Maximum).Maximum

    # ----- Tuiles -----
    $tuiles = @(
        @{ n = 'Lignes controlees';    v = ('{0:N0}' -f $enrichi.Count);     c = '#003366' }
        @{ n = 'Concordantes';         v = ('{0:N0}' -f $nbOk);              c = '#0b6b3a' }
        @{ n = 'En ecart';             v = ('{0:N0}' -f $nbKo);              c = '#9b1c1c' }
        @{ n = 'Indeterminees';        v = ('{0:N0}' -f $nbIndet);           c = '#8a5a00' }
        @{ n = 'Montant en ecart';     v = (Format-MontantRapport $montantEnEcart); c = '#9b1c1c' }
        @{ n = 'Ecart le plus ancien'; v = $(if ($null -ne $ageMax) { "$ageMax j" } else { '-' }); c = '#5b2d8e' }
        @{ n = 'En interface, non integre'; v = ('{0:N0}' -f $nbInter);      c = '#8a5a00' }
        @{ n = 'Sans reponse Oracle';  v = ('{0:N0}' -f $nbVides);           c = '#8a5a00' }
    )
    $htmlTuiles = ($tuiles | ForEach-Object {
        "<div class=""tile""><div class=""tv"" style=""color:$($_.c)"">$(ConvertTo-HtmlTexte $_.v)</div>" +
        "<div class=""tn"">$(ConvertTo-HtmlTexte $_.n)</div></div>"
    }) -join ''

    # ----- Syntheses -----
    $blocSynthese = {
        param($Titre, $Champ, $Limite)
        $g = $enrichi | Group-Object -Property $Champ | ForEach-Object {
            $mt = ($_.Group | Where-Object { $_.Statut -ne 'OK' } | Measure-Object -Property EcartMtCalc -Sum).Sum
            [PSCustomObject]@{
                Cle   = $_.Name
                Nb    = $_.Count
                Ko    = @($_.Group | Where-Object { $_.Statut -eq 'KO' }).Count
                Indet = @($_.Group | Where-Object { $_.Statut -eq 'INDETERMINE' }).Count
                Mt    = $(if ($null -eq $mt) { 0 } else { $mt })
            }
        } | Sort-Object @{ Expression = { [math]::Abs([double]$_.Mt) }; Descending = $true }
        if ($Limite -gt 0) { $g = $g | Select-Object -First $Limite }

        $l = ($g | ForEach-Object {
            $cls = if ($_.Ko -gt 0 -or $_.Indet -gt 0) { ' class="warn"' } else { '' }
            "<tr$cls><td>$(ConvertTo-HtmlTexte $_.Cle)</td><td class=""num"">$($_.Nb)</td>" +
            "<td class=""num"">$($_.Ko)</td><td class=""num"">$($_.Indet)</td>" +
            "<td class=""num strong"">$(Format-MontantRapport $_.Mt)</td></tr>"
        }) -join ''
        "<div><h3>$Titre</h3><table class=""synth""><thead><tr><th>$Champ</th><th>Lignes</th>" +
        "<th>En ecart</th><th>Indet.</th><th>Montant en ecart</th></tr></thead><tbody>$l</tbody></table></div>"
    }
    $htmlSynthese = (& $blocSynthese 'Par nature de flux' 'Type' 0) +
                    (& $blocSynthese 'Par folio (15 premiers)' 'Folio' 15)

    # ----- Detail : les ecarts d'abord, du plus lourd au plus leger -----
    $ordre = @{ 'INDETERMINE' = 1; 'KO' = 2; 'OK' = 3 }
    $triees = $enrichi | Sort-Object `
        @{ Expression = { if ($ordre.ContainsKey($_.Statut)) { $ordre[$_.Statut] } else { 9 } } },
        @{ Expression = { [math]::Abs([double]$_.EcartMtCalc) }; Descending = $true }

    $pastille = @{
        'OK'          = @{ c = '#0b6b3a'; f = '#d7f2e3' }
        'KO'          = @{ c = '#9b1c1c'; f = '#fbdcdc' }
        'INDETERMINE' = @{ c = '#8a5a00'; f = '#fdeccd' }
    }

    $htmlLignes = ($triees | ForEach-Object {
        $s = $pastille[$_.Statut]
        if (-not $s) { $s = @{ c = '#333'; f = '#eee' } }

        $clsAge = ''
        if ($null -ne $_.Age) {
            if     ($_.Age -gt 30) { $clsAge = ' age-vieux' }
            elseif ($_.Age -gt 7)  { $clsAge = ' age-moyen' }
        }
        $ageTxt = if ($null -ne $_.Age) { "$($_.Age) j" } else { '' }

        $ficCourt = $_.Fichier
        if ($ficCourt.Length -gt 46) { $ficCourt = $ficCourt.Substring(0, 45) + [char]0x2026 }

        $marqueur = ''
        if ($_.OraVide) {
            $marqueur = '<span class="flag rien" title="Aucune donnee Oracle : ni definitif, ni interface. Le flux n''est pas arrive.">rien en base</span>'
        } elseif ($_.EnInterface) {
            $marqueur = '<span class="flag inter" title="Present en interface mais absent des tables definitives : le fichier est arrive, l''integration n''a pas eu lieu.">en interface</span>'
        }

        "<tr data-statut=""$($_.Statut)"">" +
        "<td class=""mono"">$(ConvertTo-HtmlTexte $_.Folio)</td>" +
        "<td>$(ConvertTo-HtmlTexte $_.Type)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.DateTxt)</td>" +
        "<td class=""ctr$clsAge"">$ageTxt</td>" +
        "<td class=""mono fic"" title=""$(ConvertTo-HtmlTexte $_.Fichier)"">$(ConvertTo-HtmlTexte $ficCourt)</td>" +
        "<td class=""num"">$('{0:N0}' -f $_.EcartNbDecl)</td>" +
        "<td class=""num"">$(Format-MontantRapport $_.EcartDbDecl)</td>" +
        "<td class=""num sep"">$('{0:N0}' -f $_.NbOra)</td>" +
        "<td class=""num"">$(Format-MontantRapport $_.MtOra)</td>" +
        "<td class=""num"">$(Format-MontantRapport $_.MtInterface)</td>" +
        "<td class=""num sep"">$('{0:N0}' -f $_.EcartNbCalc)</td>" +
        "<td class=""num strong"">$(Format-MontantRapport $_.EcartMtCalc)</td>" +
        "<td class=""com"">$(ConvertTo-HtmlTexte $_.Commentaire)</td>" +
        "<td><span class=""pill"" style=""color:$($s.c);background:$($s.f)"">$(ConvertTo-HtmlTexte $_.Statut)</span> $marqueur</td>" +
        '</tr>'
    }) -join "`r`n"

    if ($nbKo -gt 0 -or $nbIndet -gt 0) {
        $globClass = if ($nbIndet -gt 0) { 'warn' } else { 'ko' }
        $globTitre = "$nbKo ligne(s) en ecart" + $(if ($nbIndet -gt 0) { ", $nbIndet indeterminee(s)" } else { '' })
        $globTexte = "Montant cumule en ecart : $(Format-MontantRapport $montantEnEcart)."
    } else {
        $globClass = 'ok'; $globTitre = 'Aucun ecart'
        $globTexte = 'Toutes les lignes controlees concordent avec Oracle.'
    }

    $avertVides = ''
    if ($nbInter -gt 0) {
        $avertVides += "<div class=""note""><strong>$nbInter ligne(s) presentes en interface mais absentes des tables definitives</strong> " +
                       "&mdash; le fichier est bien arrive, l'integration n'a pas eu lieu. Ce n'est pas un ecart de " +
                       "montant : c'est un traitement d'integration a relancer ou a debloquer.</div>"
    }
    if ($nbVides -gt 0) {
        $avertVides += "<div class=""note""><strong>$nbVides ligne(s) sans aucune donnee Oracle</strong> " +
                       "&mdash; ni definitif, ni interface. Le flux n'est pas arrive, ou le couple " +
                       "folio / nom de fichier ne correspond a rien en base.</div>"
    }

    $css = @'
  * { box-sizing: border-box; }
  body { font-family: Segoe UI, Calibri, Arial, sans-serif; margin: 0; padding: 22px;
         background: #f4f6f9; color: #24292f; }
  .wrap { max-width: 1700px; margin: 0 auto; }
  h1 { background: #003366; color: #fff; padding: 15px 22px; border-radius: 6px;
       font-size: 1.22em; margin: 0 0 12px 0; }
  h2 { color: #003366; border-bottom: 2px solid #003366; padding-bottom: 5px;
       margin-top: 30px; font-size: 1.04em; }
  h3 { color: #003366; font-size: .9em; margin: 16px 0 8px 0; }
  .meta { background: #e8f0fe; border-left: 4px solid #003366; padding: 9px 15px;
          margin-bottom: 15px; border-radius: 0 4px 4px 0; font-size: .85em; }
  .meta span { margin-right: 20px; display: inline-block; }
  .bandeau { padding: 13px 19px; border-radius: 6px; margin-bottom: 16px; font-size: .92em; }
  .bandeau strong { display: block; font-size: 1.14em; margin-bottom: 3px; }
  .bandeau.ok   { background: #d7f2e3; color: #0b6b3a; border: 1px solid #7fc9a3; }
  .bandeau.warn { background: #fff4d6; color: #7a5600; border: 1px solid #e8c46a; }
  .bandeau.ko   { background: #fbdcdc; color: #9b1c1c; border: 1px solid #e39292; }
  .note { background: #fff8e6; border-left: 4px solid #d9a441; padding: 9px 15px;
          border-radius: 0 4px 4px 0; margin-bottom: 16px; font-size: .84em; color: #7a5600; }
  .tiles { display: flex; flex-wrap: wrap; gap: 11px; }
  .tile { flex: 1 1 145px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px;
          padding: 13px 9px; text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  .tv { font-size: 1.45em; font-weight: 700; line-height: 1.15; }
  .tn { font-size: .73em; color: #57606a; text-transform: uppercase;
        letter-spacing: .03em; margin-top: 4px; }
  .cols { display: flex; gap: 22px; flex-wrap: wrap; }
  .cols > div { flex: 1 1 380px; }
  table { border-collapse: collapse; width: 100%; background: #fff; }
  .tablewrap { overflow-x: auto; background: #fff; border-radius: 6px;
               box-shadow: 0 1px 3px rgba(0,0,0,.12); }
  th { background: #003366; color: #fff; padding: 9px 10px; text-align: left;
       font-size: .77em; white-space: nowrap; position: sticky; top: 0; z-index: 2; }
  td { padding: 6px 10px; border-bottom: 1px solid #eceff2; font-size: .81em; white-space: nowrap; }
  tr:nth-child(even) td { background: #fafbfc; }
  tr:hover td { background: #eef4fd; }
  tr.warn td { background: #fffaf0; }
  table.synth { border-radius: 6px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,.1); }
  .mono { font-family: Consolas, Menlo, monospace; font-size: .95em; }
  .num  { text-align: right; font-variant-numeric: tabular-nums; }
  .ctr  { text-align: center; }
  .strong { font-weight: 700; }
  .sep { border-left: 2px solid #dde3ea; }
  .fic { max-width: 340px; overflow: hidden; text-overflow: ellipsis; }
  .com { max-width: 260px; white-space: normal; color: #57606a; font-style: italic; }
  td:empty::after { content: '-'; color: #c9ced4; }
  .pill { display: inline-block; padding: 2px 9px; border-radius: 11px;
          font-size: .8em; font-weight: 600; }
  .flag { display: inline-block; margin-left: 5px; padding: 1px 7px; border-radius: 9px;
          font-size: .73em; font-weight: 600; cursor: help; }
  .flag.rien  { background: #ede7f6; color: #5b2d8e; }
  .flag.inter { background: #e3f0fb; color: #0a4d8c; }
  .age-moyen { color: #8a5a00; font-weight: 600; }
  .age-vieux { color: #9b1c1c; font-weight: 700; }
  .barre { background: #fff; border-radius: 6px; padding: 11px 15px; margin-bottom: 12px;
           box-shadow: 0 1px 2px rgba(0,0,0,.08); font-size: .84em; }
  .barre button { border: 1px solid #c5cdd6; background: #f6f8fa; border-radius: 14px;
                  padding: 4px 13px; margin-right: 6px; cursor: pointer; font-size: .95em;
                  font-family: inherit; }
  .barre button.on { background: #003366; color: #fff; border-color: #003366; }
  .barre input { border: 1px solid #c5cdd6; border-radius: 4px; padding: 5px 9px;
                 width: 250px; font-family: inherit; font-size: .95em; margin-left: 10px; }
  #compteur { color: #57606a; margin-left: 12px; }
  .footer { font-size: .76em; color: #8b949e; margin-top: 30px; text-align: center; }
  @media print {
    .barre { display: none; }
    body { background: #fff; padding: 0; }
    th { position: static; }
  }
'@

    $js = @'
(function () {
  var filtreStatut = "TOUS";
  function appliquer() {
    var q = document.getElementById("q").value.toLowerCase();
    var lignes = document.querySelectorAll("#detail tbody tr");
    var visibles = 0;
    for (var i = 0; i < lignes.length; i++) {
      var tr = lignes[i];
      var okStatut = (filtreStatut === "TOUS") || (tr.getAttribute("data-statut") === filtreStatut);
      var okTexte  = (q === "") || (tr.textContent.toLowerCase().indexOf(q) >= 0);
      var visible  = okStatut && okTexte;
      tr.style.display = visible ? "" : "none";
      if (visible) { visibles++; }
    }
    document.getElementById("compteur").textContent = visibles + " ligne(s) affichee(s)";
  }
  var boutons = document.querySelectorAll(".barre button");
  for (var b = 0; b < boutons.length; b++) {
    boutons[b].addEventListener("click", function () {
      for (var k = 0; k < boutons.length; k++) { boutons[k].className = ""; }
      this.className = "on";
      filtreStatut = this.getAttribute("data-f");
      appliquer();
    });
  }
  document.getElementById("q").addEventListener("input", appliquer);
  appliquer();
})();
'@

    $ligneMeta = @()
    $ligneMeta += "<span><strong>Genere le :</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</span>"
    if ($FichierSource)    { $ligneMeta += "<span><strong>Fichier :</strong> $(ConvertTo-HtmlTexte $FichierSource)$(if ($Encodage) { " ($Encodage)" })</span>" }
    if ($Base)             { $ligneMeta += "<span><strong>Base :</strong> $(ConvertTo-HtmlTexte $Base)</span>" }
    if ($NbInterrogations) { $ligneMeta += "<span><strong>Interrogations Oracle :</strong> $NbInterrogations</span>" }
    if ($Duree)            { $ligneMeta += "<span><strong>Duree :</strong> ${Duree}s</span>" }

    $piedCsv = if ($CheminCsv) { " &mdash; donnees detaillees : $(ConvertTo-HtmlTexte (Split-Path $CheminCsv -Leaf))" } else { '' }

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Controle Folio Rose - $(Get-Date -Format 'dd/MM/yyyy HH:mm')</title>
<style>
$css
</style>
</head>
<body>
<div class="wrap">
<h1>Controle Folio Rose &mdash; reconciliation des factures</h1>
<div class="meta">$($ligneMeta -join '')</div>
<div class="bandeau $globClass"><strong>$globTitre</strong>$globTexte</div>
$avertVides
<div class="tiles">$htmlTuiles</div>

<h2>Synthese</h2>
<div class="cols">
$htmlSynthese
</div>

<h2>Detail des lignes</h2>
<div class="barre">
  <button class="on" data-f="TOUS">Toutes</button>
  <button data-f="KO">En ecart</button>
  <button data-f="INDETERMINE">Indeterminees</button>
  <button data-f="OK">Concordantes</button>
  <input type="text" id="q" placeholder="Rechercher un folio, un fichier...">
  <span id="compteur"></span>
</div>
<div class="tablewrap">
<table id="detail">
<thead><tr>
  <th>Folio</th><th>Type</th><th>Date</th><th>Age</th><th>Fichier transmis</th>
  <th>Ecart Nb<br>(fichier)</th><th>Ecart Debit<br>(fichier)</th>
  <th class="sep">Nb Oracle</th><th>Montant Oracle</th><th>Montant Interface</th>
  <th class="sep">Ecart Nb<br>(calcule)</th><th>Ecart Montant<br>(calcule)</th>
  <th>Commentaire</th><th>Statut</th>
</tr></thead>
<tbody>
$htmlLignes
</tbody>
</table>
</div>
<div class="footer">Genere par Verifier_Factures.ps1$piedCsv</div>
</div>
<script>
$js
</script>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($CheminHtml, $html, (New-Object System.Text.UTF8Encoding $true))
}
