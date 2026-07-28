# =====================================================================
#  Renvoi de factures vers DacShop - sans les images
# =====================================================================
#  Marque les factures listees dans invoice.csv comme modifiees dans
#  AP.AP_INVOICES_ALL, ce qui declenche leur reprise par l'interface.
#
#  Toute la logique est dans ..\Update_AP_Invoices_Commun.ps1 : ce script
#  et celui de EnvoiImageEtFacture etaient auparavant deux copies
#  integrales, ce qui obligeait a corriger chaque anomalie deux fois.
#
#  SIMULATION PAR DEFAUT. Pour appliquer reellement :
#     .\Update_AP_Invoices.ps1 -Executer
#     ou  Update_AP_Invoices.bat EXEC
# =====================================================================

param(
    [switch] $Executer,
    [switch] $SansConfirmation,
    [switch] $AutoriserManquants,
    [switch] $GarderTempSQL,
    [int]    $MaxLignes = 50000
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Moteur    = Join-Path (Split-Path -Parent $ScriptDir) 'Update_AP_Invoices_Commun.ps1'

if (-not (Test-Path $Moteur)) {
    Write-Host "[ERREUR] Moteur commun introuvable : $Moteur" -ForegroundColor Red
    exit 1
}

& $Moteur -CsvNom 'invoice.csv' `
          -DossierBase $ScriptDir `
          -Libelle 'Renvoi factures vers DacShop' `
          -Executer:$Executer `
          -SansConfirmation:$SansConfirmation `
          -AutoriserManquants:$AutoriserManquants `
          -GarderTempSQL:$GarderTempSQL `
          -MaxLignes $MaxLignes

exit $LASTEXITCODE
