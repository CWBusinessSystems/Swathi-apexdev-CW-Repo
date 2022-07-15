/*Class Name: CWS_ContractAmender
*Description: Standard CPQ class for calling the contract amender api
*Created By: Carl Shahan
*Created On: 08/13/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer   Date       User Story    Description
*------------------------------------------------------------------------------------------
*Carl Shahan 08/13/2020 CWH-996       Standard CPQ class for calling the contract amender api
*/
public with sharing class CWS_ContractAmender {
    public CWS_QuoteModel load(String contractId) {
        String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
        
        System.debug(quoteJSON);
        return (CWS_QuoteModel)JSON.deserialize(quoteJSON, CWS_QuoteModel.class);
    } 
}