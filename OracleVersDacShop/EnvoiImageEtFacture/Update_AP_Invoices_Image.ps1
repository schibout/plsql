# =====================================================================
#  Renvoi de factures vers DacShop - avec les images
# =====================================================================
#  Marque les factures listees dans invoiceImage.csv comme modifiees dans
#  AP.AP_INVOICES_ALL, et remet FND_ATTACHED_DOCUMENTS.ATTRIBUTE1 a NULL
#  pour que les documents attaches soient renvoyes.
#
#  Toute la logique est dans ..\Update_AP_Invoices_Commun.ps1 : ce script
#  et celui de envoiFacture etaient auparavant deux copies integrales,
#  ce qui obligeait a corriger chaque anomalie deux fois.
#
#  SIMULATION PAR DEFAUT. Pour appliquer reellement :
#     .\Update_AP_Invoices_Image.ps1 -Executer
#     ou  Update_AP_Invoices_Image.bat EXEC
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

& $Moteur -CsvNom 'invoiceImage.csv' `
          -DossierBase $ScriptDir `
          -Libelle 'Renvoi factures et images vers DacShop' `
          -AvecImages `
          -Executer:$Executer `
          -SansConfirmation:$SansConfirmation `
          -AutoriserManquants:$AutoriserManquants `
          -GarderTempSQL:$GarderTempSQL `
          -MaxLignes $MaxLignes

exit $LASTEXITCODE
