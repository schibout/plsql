"""Reconciliation a 3 niveaux : fichiers, totaux, lignes."""


def nom_dk_depuis_fin01(nom: str) -> str:
    return nom.replace("DK_FIN01_", "DK_", 1)


def controle_fichiers(guid, dk_names, dkfin01_source, dkfin01_cible, ack_names, oracle_rows):
    lignes = []

    def ajoute(categorie, fichier, present, detail=""):
        lignes.append({
            "guid": guid,
            "categorie": categorie,
            "fichier": fichier,
            "statut": "OK" if present else "MANQUANT",
            "detail": detail,
        })

    for row in oracle_rows:
        dk = nom_dk_depuis_fin01(row.nom_fichier_source)
        ajoute("DK", dk, dk in dk_names, "attendu via Oracle")
        ajoute("DK_FIN01_source", row.nom_fichier_source, row.nom_fichier_source in dkfin01_source)
        ajoute("DK_FIN01_cible", row.nom_fichier_source, row.nom_fichier_source in dkfin01_cible)
        ajoute("ACK", row.nom_fichier_edf, row.nom_fichier_edf in ack_names)

    # Orphelins : fichiers presents mais non references par Oracle
    references_fin01 = {r.nom_fichier_source for r in oracle_rows}
    for nom in sorted(dkfin01_cible - references_fin01):
        lignes.append({
            "guid": guid, "categorie": "DK_FIN01_cible", "fichier": nom,
            "statut": "ORPHELIN", "detail": "present mais non reference par Oracle",
        })
    references_ack = {r.nom_fichier_edf for r in oracle_rows}
    for nom in sorted(ack_names - references_ack):
        lignes.append({
            "guid": guid, "categorie": "ACK", "fichier": nom,
            "statut": "ORPHELIN", "detail": "present mais non reference par Oracle",
        })
    return lignes


def _somme(lot):
    return sum(v.montant_cts for v in lot.virements) if lot else None


def _nb(lot):
    return len(lot.virements) if lot else None


def _tous_egaux(valeurs):
    """OK si toutes les valeurs sont presentes (non None) et identiques."""
    presentes = [v for v in valeurs if v is not None]
    return len(presentes) == len(valeurs) and len(set(presentes)) == 1


def controle_totaux_source(guid, nom_source, dk, dkfin01, oracle_row):
    """Coherence cote source, par fichier : DK == DK_FIN01 == Oracle (colonnes source)."""
    nb_dk = _nb(dk)
    nb_dkf = _nb(dkfin01)
    nb_ora = oracle_row.nb_source if oracle_row else None

    m_dk_entete = dk.montant_entete_cts if dk else None
    m_dk = _somme(dk)
    m_dkf = _somme(dkfin01)
    m_ora = oracle_row.montant_source_cts if oracle_row else None

    return {
        "guid": guid,
        "fichier_source": nom_source,
        "nb_dk": nb_dk, "nb_dk_fin01": nb_dkf, "nb_oracle_source": nb_ora,
        "montant_dk_entete": m_dk_entete, "montant_dk": m_dk,
        "montant_dk_fin01": m_dkf, "montant_oracle_source": m_ora,
        "euro_lines": dkfin01.euro_lines if dkfin01 else None,
        "statut_lignes": "OK" if _tous_egaux([nb_dk, nb_dkf, nb_ora]) else "KO",
        "statut_montant": "OK" if _tous_egaux([m_dk_entete, m_dk, m_dkf, m_ora]) else "KO",
    }


def controle_totaux_edf(guid, nom_edf, ack, oracle_rows_groupe):
    """Coherence cote EDF, par fichier ACK regroupant N sources.

    ack.footer == detail ACK == Oracle (colonnes EDF) == somme des colonnes source du groupe.
    """
    nb_ack = ack.footer_count if ack else None
    nb_ack_detail = _nb(ack)
    nb_ora_edf = oracle_rows_groupe[0].nb_edf if oracle_rows_groupe else None
    nb_somme_src = sum(r.nb_source for r in oracle_rows_groupe) if oracle_rows_groupe else None

    m_ack_footer = ack.footer_total_cts if ack else None
    m_ack_detail = _somme(ack)
    m_ora_edf = oracle_rows_groupe[0].montant_edf_cts if oracle_rows_groupe else None
    m_somme_src = sum(r.montant_source_cts for r in oracle_rows_groupe) if oracle_rows_groupe else None

    return {
        "guid": guid,
        "fichier_edf": nom_edf,
        "nb_sources_regroupees": len(oracle_rows_groupe),
        "nb_ack_footer": nb_ack, "nb_ack_detail": nb_ack_detail,
        "nb_oracle_edf": nb_ora_edf, "nb_somme_sources": nb_somme_src,
        "montant_ack_footer": m_ack_footer, "montant_ack_detail": m_ack_detail,
        "montant_oracle_edf": m_ora_edf, "montant_somme_sources": m_somme_src,
        "statut_lignes": "OK" if _tous_egaux([nb_ack, nb_ack_detail, nb_ora_edf, nb_somme_src]) else "KO",
        "statut_montant": "OK" if _tous_egaux([m_ack_footer, m_ack_detail, m_ora_edf, m_somme_src]) else "KO",
    }


def _norm_nom(s: str) -> str:
    return " ".join(s.split()).upper()


def _noms_compatibles(nom_dk, nom_ack):
    """Tolere la troncature ACK : un nom est un prefixe de l'autre une fois normalise."""
    a = _norm_nom(nom_dk)
    b = _norm_nom(nom_ack)
    if a == b:
        return True
    court, long = (b, a) if len(b) <= len(a) else (a, b)
    return bool(court) and long.startswith(court)


def _bic_compatibles(bic_dk, bic_ack):
    """Tolere le padding BIC8 -> BIC11 : 'SOGEFRPP' == 'SOGEFRPPXXX'."""
    a = bic_dk.strip().upper()
    b = bic_ack.strip().upper()
    if not a or not b:
        return True
    return a.rstrip("X").rstrip() == b.rstrip("X").rstrip() or a == b


def _index_par_cle(virements):
    index = {}
    for v in virements:
        index.setdefault((v.iban, v.montant_cts), []).append(v)
    return index


def controle_lignes(guid, nom_lot, dkfin01_lots, ack):
    """Rapproche l'union des virements des DK_FIN01 regroupes contre l'ACK.

    dkfin01_lots : liste de LotDK (un seul element pour un flux 1:1).
    """
    ecarts = []
    virements_dkf = [v for lot in dkfin01_lots for v in lot.virements]
    idx_dkf = _index_par_cle(virements_dkf)
    idx_ack = _index_par_cle(ack.virements)

    for cle, vs_dkf in idx_dkf.items():
        vs_ack = idx_ack.get(cle, [])
        iban, montant = cle
        if len(vs_ack) < len(vs_dkf):
            ecarts.append({
                "guid": guid, "lot": nom_lot, "iban": iban, "montant_cts": montant,
                "type_ecart": "ABSENT_ACK", "cote": "DK_FIN01",
                "detail": f"{len(vs_dkf)} cote DK_FIN01 / {len(vs_ack)} cote ACK",
            })
            continue
        for vd, va in zip(vs_dkf, vs_ack):
            if not _noms_compatibles(vd.nom, va.nom):
                ecarts.append({
                    "guid": guid, "lot": nom_lot, "iban": iban, "montant_cts": montant,
                    "type_ecart": "NOM_DIFFERENT", "cote": "DK_FIN01|ACK",
                    "detail": f"DK_FIN01='{vd.nom}' ACK='{va.nom}'",
                })
            if not _bic_compatibles(vd.bic, va.bic):
                ecarts.append({
                    "guid": guid, "lot": nom_lot, "iban": iban, "montant_cts": montant,
                    "type_ecart": "BIC_DIFFERENT", "cote": "DK_FIN01|ACK",
                    "detail": f"DK_FIN01='{vd.bic}' ACK='{va.bic}'",
                })

    for cle, vs_ack in idx_ack.items():
        vs_dkf = idx_dkf.get(cle, [])
        if len(vs_dkf) < len(vs_ack):
            iban, montant = cle
            ecarts.append({
                "guid": guid, "lot": nom_lot, "iban": iban, "montant_cts": montant,
                "type_ecart": "ABSENT_DK_FIN01", "cote": "ACK",
                "detail": f"{len(vs_dkf)} cote DK_FIN01 / {len(vs_ack)} cote ACK",
            })
    return ecarts


def controle_quartz(cible_virements, quartz_virements):
    """Niveau 3 : rapproche l'import Quartz (tresorerie) contre les virements cible envoyes.

    Retourne (totaux: dict, ecarts: list[dict]). Rapprochement par montant (centimes),
    avec comparaison du nom du beneficiaire sur les paires appariees.
    """
    nb_cible = len(cible_virements)
    nb_quartz = len(quartz_virements)
    m_cible = sum(v.montant_cts for v in cible_virements)
    m_quartz = sum(v.montant_cts for v in quartz_virements)

    idx_cible = {}
    for v in cible_virements:
        idx_cible.setdefault(v.montant_cts, []).append(v)
    idx_quartz = {}
    for v in quartz_virements:
        idx_quartz.setdefault(v.montant_cts, []).append(v)

    ecarts = []
    for montant in sorted(set(idx_cible) | set(idx_quartz)):
        vc = sorted(idx_cible.get(montant, []), key=lambda v: _norm_nom(v.nom))
        vq = sorted(idx_quartz.get(montant, []), key=lambda v: _norm_nom(v.nom))
        for i in range(min(len(vc), len(vq))):
            if not _noms_compatibles(vc[i].nom, vq[i].nom):
                ecarts.append({
                    "montant_cts": montant, "type_ecart": "NOM_DIFFERENT",
                    "detail": f"cible='{vc[i].nom}' quartz='{vq[i].nom}'",
                })
        for v in vc[len(vq):]:
            ecarts.append({
                "montant_cts": montant, "type_ecart": "ABSENT_QUARTZ",
                "detail": f"envoye vers '{v.nom}' absent de l'import Quartz",
            })
        for v in vq[len(vc):]:
            ecarts.append({
                "montant_cts": montant, "type_ecart": "ABSENT_CIBLE",
                "detail": f"importe par Quartz ('{v.nom}') mais non envoye",
            })

    totaux = {
        "nb_cible": nb_cible, "nb_quartz": nb_quartz,
        "montant_cible_cts": m_cible, "montant_quartz_cts": m_quartz,
        "statut_lignes": "OK" if nb_cible == nb_quartz and not ecarts else "KO",
        "statut_montant": "OK" if m_cible == m_quartz else "KO",
    }
    return totaux, ecarts
