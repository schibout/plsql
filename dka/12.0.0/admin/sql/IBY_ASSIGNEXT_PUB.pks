CREATE OR REPLACE PACKAGE IBY_ASSIGNEXT_PUB AUTHID CURRENT_USER AS
/*$Header: ibyasgnexts.pls 120.1 2009/06/25 09:18:39 jnallam noship $*/
 --
 --

/*--------------------------------------------------------------------
 | NAME:
 |      hookForAssignments
 |
 | PURPOSE:
 |
 |
 |
 | PARAMETERS:
 |     IN
 |
 |     OUT
 |
 |
 | RETURNS:
 |
 | NOTES:
 |     This method should be implemented on-site by the customer
 |     (if the customer wants to implement any custom defaulting
 |     logic for documents that do not have their internal bank
 |     account, and/or payment profile).
 |
 |     This method will ship with an empty body out-of-the-box
 |     from Oracle Payments.
 |
 *---------------------------------------------------------------------*/
 PROCEDURE hookForAssignments(
     x_unassgnDocsTab IN OUT NOCOPY IBY_ASSIGN_PUB.unassignedDocsTabType
     );


 END IBY_ASSIGNEXT_PUB;
/
SHOW ERRORS PACKAGE IBY_ASSIGNEXT_PUB
EXIT
