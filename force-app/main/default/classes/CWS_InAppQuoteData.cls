/** Class Name: CWS_InAppQuoteData
* @description: Custom In App class used to convert the CW Home payload to a useable class in the In App code
* @author Created By: Carl Shahan
* @date 02/11/2022
* Modification Log
* ------------------------------------------------------------------------------------------
* Developer   Date       User Story    Description
* ------------------------------------------------------------------------------------------
* Carl Shahan 02/11/2022 OBD-3769      Created as part of refactoring and bug fixes to ensure correct prorated pricing 
*/
/** @description QuoteData class containing the values quoted to the partner in the CW Home interface used to create the In App purchase */
public with sharing class CWS_InAppQuoteData {
    /** @description property containing the Contract Id for the quote */
    public String contractId {get; set;}
    /** @description property containing the quoted price for the quote */
    public Decimal quotedPrice {get; set;}
    /** @description property containing the quoted quantity for the quote */
    public Decimal quotedQuantity {get; set;}
    /** @description property containing the Subscription Id for the quote */
    public String subscriptionId {get; set;}
    /** @description property containing the Product Id for the quote */
    public String productId {get; set;}
    /** @description property containing the Product Code for the quote */
    public String productCode {get; set;}
    /** @description property containing the Product Name for the quote */
    public String productName {get; set;}
    /** @description property containing the purchaser email for the quote */
    public String purchaserEmail {get; set;}
    /** @description property containing the purchaser first name for the quote */
    public String purchaserFirstName {get; set;}
    /** @description property containing the purchaser last name for the quote */
    public String purchaserLastName {get; set;}
}