#Requires -Version 5.1
# =====================================================================
#  Generation du rapport HTML - doublons Open Interface AR
# =====================================================================
#  Ce fichier ne fait que definir New-RapportDoublonsHtml. Il est charge
#  par point-source depuis Suppression_Doublons.ps1.
#
#  ENCODAGE : ce fichier est en ASCII pur, il se lit correctement quel
#  que soit l'encodage suppose. Si un accent y est introduit un jour,
#  l'enregistrer alors en UTF-8 AVEC BOM, sinon PowerShell le lira en
#  ANSI et les libelles du rapport sortiront abimes.
# =====================================================================

function ConvertTo-HtmlTexte {
    param([string]$T)
    if ([string]::IsNullOrEmpty($T)) { return '' }
    return $T.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

function Format-MontantHtml {
    param($V)
    return ('{0:N2}' -f [double]$V)
}

function New-RapportDoublonsHtml {
    param(
        [Parameter(Mandatory = $true)] $Lignes,          # ##LINE##
        [Parameter(Mandatory = $true)] $Erreurs,         # ##ERR##
        [Parameter(Mandatory = $true)] $Distributions,   # ##DIST##
        [Parameter(Mandatory = $true)] $CreditsVente,    # ##SC##
        [Parameter(Mandatory = $true)] [string] $CheminHtml,
        [hashtable] $Compteurs = @{},
        [string] $Mode     = 'SIMULATION',
        [string] $Motif    = '',
        [string] $Org      = '',
        [string] $Base     = '',
        [double] $Duree    = 0,
        [string] $CheminCsv = '',
        [int]    $MaxDetailEnfants = 3000
    )

    $lg = @($Lignes)
    $er = @($Erreurs)
    $di = @($Distributions)
    $sc = @($CreditsVente)

    $montantTotal = ($lg | Measure-Object -Property Montant -Sum).Sum
    if ($null -eq $montantTotal) { $montantTotal = 0 }

    # Deux populations tres differentes derriere le meme message d'erreur.
    #  - deja integree : la facture existe dans RA_CUSTOMER_TRX_ALL, la
    #    ligne d'interface fait double emploi, la purge est sans risque.
    #  - doublon interne : le numero n'existe qu'en interface, en
    #    plusieurs exemplaires. Tout supprimer ferait perdre la facture.
    #    C'est le seul cas ou la purge doit etre arbitree avant d'agir.
    $dejaIntegrees = @($lg | Where-Object { [int]$_.NbTrxExistantes -gt 0 })
    $internes      = @($lg | Where-Object { [int]$_.NbTrxExistantes -eq 0 -and [int]$_.NbDansInterface -gt 1 })
    $isoles        = @($lg | Where-Object { [int]$_.NbTrxExistantes -eq 0 -and [int]$_.NbDansInterface -le 1 })

    $nbOrg    = @($lg | Select-Object -ExpandProperty OrgId -Unique).Count
    $nbSource = @($lg | Select-Object -ExpandProperty Source -Unique).Count

    $cSc   = if ($Compteurs.ContainsKey('RA_INTERFACE_SALESCREDITS_ALL'))   { $Compteurs['RA_INTERFACE_SALESCREDITS_ALL'] }   else { $sc.Count }
    $cDist = if ($Compteurs.ContainsKey('RA_INTERFACE_DISTRIBUTIONS_ALL'))  { $Compteurs['RA_INTERFACE_DISTRIBUTIONS_ALL'] }  else { $di.Count }
    $cErr  = if ($Compteurs.ContainsKey('RA_INTERFACE_ERRORS_ALL'))         { $Compteurs['RA_INTERFACE_ERRORS_ALL'] }         else { $er.Count }
    $cLig  = if ($Compteurs.ContainsKey('RA_INTERFACE_LINES_ALL'))          { $Compteurs['RA_INTERFACE_LINES_ALL'] }          else { $lg.Count }
    $total = [int]$cSc + [int]$cDist + [int]$cErr + [int]$cLig

    # ----- Tuiles -----
    $tuiles = @(
        @{ n = 'Enregistrements supprimes'; v = ('{0:N0}' -f $total);        c = '#9b1c1c' }
        @{ n = 'Lignes d''interface';       v = ('{0:N0}' -f [int]$cLig);    c = '#003366' }
        @{ n = 'Erreurs';                   v = ('{0:N0}' -f [int]$cErr);    c = '#003366' }
        @{ n = 'Distributions';             v = ('{0:N0}' -f [int]$cDist);   c = '#003366' }
        @{ n = 'Credits de vente';          v = ('{0:N0}' -f [int]$cSc);     c = '#003366' }
        @{ n = 'Montant concerne';          v = (Format-MontantHtml $montantTotal); c = '#5b2d8e' }
        @{ n = 'Deja integrees en base';    v = ('{0:N0}' -f $dejaIntegrees.Count); c = '#0b6b3a' }
        @{ n = 'Doublons internes';         v = ('{0:N0}' -f $internes.Count);      c = '#8a5a00' }
        @{ n = 'Organisations';             v = ('{0:N0}' -f $nbOrg);        c = '#57606a' }
        @{ n = 'Sources';                   v = ('{0:N0}' -f $nbSource);     c = '#57606a' }
    )
    $htmlTuiles = ($tuiles | ForEach-Object {
        "<div class=""tile""><div class=""tv"" style=""color:$($_.c)"">$(ConvertTo-HtmlTexte $_.v)</div>" +
        "<div class=""tn"">$(ConvertTo-HtmlTexte $_.n)</div></div>"
    }) -join ''

    # ----- Bandeau -----
    if ($lg.Count -eq 0) {
        $globClass = 'ok'
        $globTitre = 'Aucune ligne a supprimer'
        $globTexte = "Aucun enregistrement de l'interface AR ne porte le motif recherche."
    } elseif ($Mode -eq 'EXECUTION') {
        $globClass = 'ko'
        $globTitre = "$total enregistrement(s) supprime(s) definitivement"
        $globTexte = "$($lg.Count) ligne(s) d'interface et leurs enfants, pour $(Format-MontantHtml $montantTotal) au total."
    } else {
        $globClass = 'warn'
        $globTitre = "$total enregistrement(s) seraient supprime(s)"
        $globTexte = "$($lg.Count) ligne(s) d'interface et leurs enfants, pour $(Format-MontantHtml $montantTotal) au total. " +
                     'Rien n''a ete modifie en base : ce rapport est une simulation.'
    }

    # ----- Avertissements : ce qui doit etre lu avant de valider -----
    $notes = ''
    if ($internes.Count -gt 0) {
        $notes += "<div class=""note danger""><strong>$($internes.Count) ligne(s) en doublon interne a l'interface</strong> " +
                  "&mdash; leur numero de facture n'existe dans aucune table definitive, mais apparait plusieurs fois " +
                  "en interface. Supprimer tous les exemplaires ferait perdre la facture. Ces lignes sont signalees " +
                  "<span class=""flag interne"">interne</span> dans le detail : les arbitrer avant d'executer la purge.</div>"
    }
    if ($isoles.Count -gt 0) {
        $notes += "<div class=""note""><strong>$($isoles.Count) ligne(s) sans exemplaire concurrent identifie</strong> " +
                  "&mdash; ni facture integree portant ce numero, ni autre ligne d'interface. Le rejet EBS peut venir " +
                  "d'un doublon detecte sur un autre critere que le numero, ou d'une facture purgee depuis. A verifier.</div>"
    }
    if ($dejaIntegrees.Count -gt 0) {
        $notes += "<div class=""note ok""><strong>$($dejaIntegrees.Count) ligne(s) dont la facture est deja integree</strong> " +
                  "&mdash; le numero existe dans RA_CUSTOMER_TRX_ALL. Ce sont les vrais doublons, leur suppression " +
                  "ne fait perdre aucune donnee comptable.</div>"
    }

    # ----- Syntheses par organisation et par source -----
    $blocSynthese = {
        param($Titre, $Champ, $Limite)
        $g = $lg | Group-Object -Property $Champ | ForEach-Object {
            $mt = ($_.Group | Measure-Object -Property Montant -Sum).Sum
            [PSCustomObject]@{
                Cle     = $(if ([string]::IsNullOrEmpty($_.Name)) { '(vide)' } else { $_.Name })
                Nb      = $_.Count
                Deja    = @($_.Group | Where-Object { [int]$_.NbTrxExistantes -gt 0 }).Count
                Interne = @($_.Group | Where-Object { [int]$_.NbTrxExistantes -eq 0 -and [int]$_.NbDansInterface -gt 1 }).Count
                Mt      = $(if ($null -eq $mt) { 0 } else { $mt })
            }
        } | Sort-Object -Property Nb -Descending
        if ($Limite -gt 0) { $g = $g | Select-Object -First $Limite }

        $l = ($g | ForEach-Object {
            $cls = if ($_.Interne -gt 0) { ' class="warn"' } else { '' }
            "<tr$cls><td>$(ConvertTo-HtmlTexte $_.Cle)</td><td class=""num"">$($_.Nb)</td>" +
            "<td class=""num"">$($_.Deja)</td><td class=""num"">$($_.Interne)</td>" +
            "<td class=""num strong"">$(Format-MontantHtml $_.Mt)</td></tr>"
        }) -join ''
        "<div><h3>$Titre</h3><table class=""synth""><thead><tr><th>$Champ</th><th>Lignes</th>" +
        "<th>Deja integrees</th><th>Interne</th><th>Montant</th></tr></thead><tbody>$l</tbody></table></div>"
    }
    $htmlSynthese = (& $blocSynthese 'Par organisation' 'OrgId' 0) +
                    (& $blocSynthese 'Par source (20 premieres)' 'Source' 20)

    # ----- Detail des lignes : les cas a arbitrer en premier -----
    $triees = $lg | Sort-Object `
        @{ Expression = { if ([int]$_.NbTrxExistantes -eq 0 -and [int]$_.NbDansInterface -gt 1) { 1 }
                          elseif ([int]$_.NbTrxExistantes -eq 0) { 2 } else { 3 } } },
        @{ Expression = { [math]::Abs([double]$_.Montant) }; Descending = $true }

    $htmlLignes = ($triees | ForEach-Object {
        if ([int]$_.NbTrxExistantes -gt 0) {
            $cat = 'DEJA'; $lib = 'deja integree'; $col = '#0b6b3a'; $fond = '#d7f2e3'
        } elseif ([int]$_.NbDansInterface -gt 1) {
            $cat = 'INTERNE'; $lib = 'doublon interne'; $col = '#8a5a00'; $fond = '#fdeccd'
        } else {
            $cat = 'ISOLE'; $lib = 'sans concurrent'; $col = '#5b2d8e'; $fond = '#ede7f6'
        }

        $refTrx = if ([int]$_.NbTrxExistantes -gt 0) {
            "$($_.NbTrxExistantes) le $(ConvertTo-HtmlTexte $_.DateTrxExistante)"
        } else { '' }

        "<tr data-cat=""$cat"">" +
        "<td class=""mono"">$(ConvertTo-HtmlTexte $_.InterfaceLineId)</td>" +
        "<td>$(ConvertTo-HtmlTexte $_.Source)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.OrgId)</td>" +
        "<td class=""mono strong"">$(ConvertTo-HtmlTexte $_.TrxNumber)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.TrxDate)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.GlDate)</td>" +
        "<td class=""num strong"">$(Format-MontantHtml $_.Montant)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.Devise)</td>" +
        "<td class=""mono"">$(ConvertTo-HtmlTexte $_.ClientRef)</td>" +
        "<td>$(ConvertTo-HtmlTexte $_.TypeTrx)</td>" +
        "<td class=""com"" title=""$(ConvertTo-HtmlTexte $_.Description)"">$(ConvertTo-HtmlTexte $_.Description)</td>" +
        "<td class=""ctr sep"">$(ConvertTo-HtmlTexte $_.NbErreurs)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.NbDistributions)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.NbSalescredits)</td>" +
        "<td class=""ctr sep"">$(ConvertTo-HtmlTexte $refTrx)</td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.NbDansInterface)</td>" +
        "<td class=""com"" title=""$(ConvertTo-HtmlTexte $_.Message)"">$(ConvertTo-HtmlTexte $_.Message)</td>" +
        "<td><span class=""pill"" style=""color:$col;background:$fond"">$lib</span></td>" +
        "<td class=""ctr"">$(ConvertTo-HtmlTexte $_.CreationDate)</td>" +
        '</tr>'
    }) -join "`r`n"

    # ----- Tables enfants -----
    # Au-dela du plafond, la table est tronquee a l'affichage et le dit.
    # Le CSV, lui, reste complet : c'est lui qui fait foi pour un controle
    # exhaustif, le HTML sert a comprendre et a decider.
    $blocEnfants = {
        param($Titre, $Id, $Donnees, $Entetes, $Rendu, $Cible)
        $n = @($Donnees).Count
        if ($n -eq 0) {
            return "<h2>$Titre</h2><div class=""note"">Aucun enregistrement dans $Cible.</div>"
        }
        $affiches = @($Donnees | Select-Object -First $MaxDetailEnfants)
        $tronque = ''
        if ($n -gt $MaxDetailEnfants) {
            $tronque = "<div class=""note""><strong>Affichage limite aux $MaxDetailEnfants premieres lignes sur $n</strong> " +
                       "&mdash; la liste complete est dans le fichier CSV joint.</div>"
        }
        $th = ($Entetes | ForEach-Object { "<th>$_</th>" }) -join ''
        $tr = ($affiches | ForEach-Object { & $Rendu $_ }) -join "`r`n"
        "<h2>$Titre <span class=""cnt"">$('{0:N0}' -f $n) ligne(s) &mdash; $Cible</span></h2>$tronque" +
        "<div class=""tablewrap""><table id=""$Id""><thead><tr>$th</tr></thead><tbody>$tr</tbody></table></div>"
    }

    $htmlErreurs = & $blocEnfants 'Erreurs supprimees' 'terr' $er `
        @('Line ID', 'Message', 'Valeur invalide', 'Org') `
        { param($e) "<tr><td class=""mono"">$(ConvertTo-HtmlTexte $e.InterfaceLineId)</td>" +
                    "<td class=""com"">$(ConvertTo-HtmlTexte $e.Message)</td>" +
                    "<td class=""mono"">$(ConvertTo-HtmlTexte $e.ValeurInvalide)</td>" +
                    "<td class=""ctr"">$(ConvertTo-HtmlTexte $e.OrgId)</td></tr>" } `
        'RA_INTERFACE_ERRORS_ALL'

    $htmlDist = & $blocEnfants 'Distributions supprimees' 'tdist' $di `
        @('Distribution ID', 'Line ID', 'Classe', 'Montant', 'Pourcentage', 'Org') `
        { param($d) "<tr><td class=""mono"">$(ConvertTo-HtmlTexte $d.DistributionId)</td>" +
                    "<td class=""mono"">$(ConvertTo-HtmlTexte $d.InterfaceLineId)</td>" +
                    "<td>$(ConvertTo-HtmlTexte $d.Classe)</td>" +
                    "<td class=""num"">$(ConvertTo-HtmlTexte $d.Montant)</td>" +
                    "<td class=""num"">$(ConvertTo-HtmlTexte $d.Pourcentage)</td>" +
                    "<td class=""ctr"">$(ConvertTo-HtmlTexte $d.OrgId)</td></tr>" } `
        'RA_INTERFACE_DISTRIBUTIONS_ALL'

    $htmlSc = & $blocEnfants 'Credits de vente supprimes' 'tsc' $sc `
        @('Salescredit ID', 'Line ID', 'Commercial', 'Montant', 'Pourcentage', 'Org') `
        { param($s) "<tr><td class=""mono"">$(ConvertTo-HtmlTexte $s.SalescreditId)</td>" +
                    "<td class=""mono"">$(ConvertTo-HtmlTexte $s.InterfaceLineId)</td>" +
                    "<td>$(ConvertTo-HtmlTexte $s.Commercial)</td>" +
                    "<td class=""num"">$(ConvertTo-HtmlTexte $s.Montant)</td>" +
                    "<td class=""num"">$(ConvertTo-HtmlTexte $s.Pourcentage)</td>" +
                    "<td class=""ctr"">$(ConvertTo-HtmlTexte $s.OrgId)</td></tr>" } `
        'RA_INTERFACE_SALESCREDITS_ALL'

    $css = @'
  * { box-sizing: border-box; }
  body { font-family: Segoe UI, Calibri, Arial, sans-serif; margin: 0; padding: 22px;
         background: #f4f6f9; color: #24292f; }
  .wrap { max-width: 1800px; margin: 0 auto; }
  h1 { background: #003366; color: #fff; padding: 15px 22px; border-radius: 6px;
       font-size: 1.22em; margin: 0 0 12px 0; }
  h1.exec { background: #9b1c1c; }
  h2 { color: #003366; border-bottom: 2px solid #003366; padding-bottom: 5px;
       margin-top: 32px; font-size: 1.04em; }
  h2 .cnt { font-weight: 400; font-size: .82em; color: #57606a; margin-left: 8px; }
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
          border-radius: 0 4px 4px 0; margin-bottom: 12px; font-size: .84em; color: #7a5600; }
  .note.danger { background: #fbdcdc; border-left-color: #9b1c1c; color: #9b1c1c; }
  .note.ok { background: #eaf7f0; border-left-color: #0b6b3a; color: #0b6b3a; }
  .tiles { display: flex; flex-wrap: wrap; gap: 11px; }
  .tile { flex: 1 1 140px; background: #fff; border: 1px solid #dde3ea; border-radius: 6px;
          padding: 13px 9px; text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,.05); }
  .tv { font-size: 1.42em; font-weight: 700; line-height: 1.15; }
  .tn { font-size: .72em; color: #57606a; text-transform: uppercase;
        letter-spacing: .03em; margin-top: 4px; }
  .cols { display: flex; gap: 22px; flex-wrap: wrap; }
  .cols > div { flex: 1 1 380px; }
  table { border-collapse: collapse; width: 100%; background: #fff; }
  .tablewrap { overflow-x: auto; background: #fff; border-radius: 6px;
               box-shadow: 0 1px 3px rgba(0,0,0,.12); max-height: 720px; overflow-y: auto; }
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
  .com { max-width: 300px; overflow: hidden; text-overflow: ellipsis;
         color: #57606a; font-style: italic; }
  td:empty::after { content: '-'; color: #c9ced4; }
  .pill { display: inline-block; padding: 2px 9px; border-radius: 11px;
          font-size: .8em; font-weight: 600; }
  .flag { display: inline-block; padding: 1px 7px; border-radius: 9px;
          font-size: .78em; font-weight: 600; }
  .flag.interne { background: #fdeccd; color: #8a5a00; }
  .barre { background: #fff; border-radius: 6px; padding: 11px 15px; margin-bottom: 12px;
           box-shadow: 0 1px 2px rgba(0,0,0,.08); font-size: .84em; }
  .barre button { border: 1px solid #c5cdd6; background: #f6f8fa; border-radius: 14px;
                  padding: 4px 13px; margin-right: 6px; cursor: pointer; font-size: .95em;
                  font-family: inherit; }
  .barre button.on { background: #003366; color: #fff; border-color: #003366; }
  .barre input { border: 1px solid #c5cdd6; border-radius: 4px; padding: 5px 9px;
                 width: 260px; font-family: inherit; font-size: .95em; margin-left: 10px; }
  #compteur { color: #57606a; margin-left: 12px; }
  .footer { font-size: .76em; color: #8b949e; margin-top: 30px; text-align: center; }
  @media print {
    .barre { display: none; }
    body { background: #fff; padding: 0; }
    th { position: static; }
    .tablewrap { max-height: none; }
  }
'@

    $js = @'
(function () {
  var filtreCat = "TOUS";
  function appliquer() {
    var q = document.getElementById("q").value.toLowerCase();
    var lignes = document.querySelectorAll("#detail tbody tr");
    var visibles = 0;
    for (var i = 0; i < lignes.length; i++) {
      var tr = lignes[i];
      var okCat   = (filtreCat === "TOUS") || (tr.getAttribute("data-cat") === filtreCat);
      var okTexte = (q === "") || (tr.textContent.toLowerCase().indexOf(q) >= 0);
      var visible = okCat && okTexte;
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
      filtreCat = this.getAttribute("data-f");
      appliquer();
    });
  }
  document.getElementById("q").addEventListener("input", appliquer);
  appliquer();
})();
'@

    $ligneMeta = @()
    $ligneMeta += "<span><strong>Genere le :</strong> $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</span>"
    $ligneMeta += "<span><strong>Mode :</strong> $(ConvertTo-HtmlTexte $Mode)</span>"
    if ($Motif) { $ligneMeta += "<span><strong>Motif :</strong> $(ConvertTo-HtmlTexte $Motif)</span>" }
    if ($Org)   { $ligneMeta += "<span><strong>Organisation :</strong> $(ConvertTo-HtmlTexte $Org)</span>" }
    if ($Base)  { $ligneMeta += "<span><strong>Base :</strong> $(ConvertTo-HtmlTexte $Base)</span>" }
    if ($Duree) { $ligneMeta += "<span><strong>Duree :</strong> ${Duree}s</span>" }

    $piedCsv = if ($CheminCsv) { " &mdash; donnees detaillees : $(ConvertTo-HtmlTexte (Split-Path $CheminCsv -Leaf))" } else { '' }
    $classeH1 = if ($Mode -eq 'EXECUTION') { ' class="exec"' } else { '' }
    $titreH1  = if ($Mode -eq 'EXECUTION') {
        'Doublons Open Interface AR &mdash; enregistrements supprimes'
    } else {
        'Doublons Open Interface AR &mdash; enregistrements qui seraient supprimes'
    }

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Doublons Open Interface AR - $(Get-Date -Format 'dd/MM/yyyy HH:mm')</title>
<style>
$css
</style>
</head>
<body>
<div class="wrap">
<h1$classeH1>$titreH1</h1>
<div class="meta">$($ligneMeta -join '')</div>
<div class="bandeau $globClass"><strong>$globTitre</strong>$globTexte</div>
$notes
<div class="tiles">$htmlTuiles</div>

<h2>Synthese</h2>
<div class="cols">
$htmlSynthese
</div>

<h2>Lignes d'interface <span class="cnt">$('{0:N0}' -f $lg.Count) ligne(s) &mdash; RA_INTERFACE_LINES_ALL</span></h2>
<div class="barre">
  <button class="on" data-f="TOUS">Toutes</button>
  <button data-f="INTERNE">Doublons internes</button>
  <button data-f="ISOLE">Sans concurrent</button>
  <button data-f="DEJA">Deja integrees</button>
  <input type="text" id="q" placeholder="Rechercher un numero, un client, une source...">
  <span id="compteur"></span>
</div>
<div class="tablewrap">
<table id="detail">
<thead><tr>
  <th>Line ID</th><th>Source</th><th>Org</th><th>N facture</th><th>Date</th><th>Date GL</th>
  <th>Montant</th><th>Devise</th><th>Ref client</th><th>Type</th><th>Description</th>
  <th class="sep">Err.</th><th>Dist.</th><th>Cred.</th>
  <th class="sep">Deja en base</th><th>Exemplaires<br>en interface</th>
  <th>Message</th><th>Categorie</th><th>Creee le</th>
</tr></thead>
<tbody>
$htmlLignes
</tbody>
</table>
</div>

$htmlErreurs

$htmlDist

$htmlSc

<div class="footer">Genere par Suppression_Doublons.ps1$piedCsv</div>
</div>
<script>
$js
</script>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($CheminHtml, $html, (New-Object System.Text.UTF8Encoding $true))
}
