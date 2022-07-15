global class LeanDataCustomInterface extends LeanData.CustomInterface {

  global override Map<String, List<String>> getMapOfCustomInterfaceNodeNamesToEdges(){
    Map<String, List<String>> customInterfaceMap = new Map<String, List<String>>();
    customInterfaceMap.put('Existing Subscription for Product?', new List<String>{'Subscription Exists','No Subscription Found'});
    
    return customInterfaceMap;
  }

  global override Set<String> getCustomLeadFields() {
    Set<String> leadFields = new Set<String>{'CWS_Product_Intrest__c'};
    return leadFields;
  }

  global override Set<String> getCustomContactFields() {
    Set<String> leadFields = new Set<String>{'CWS_Product_Interest__c'};
    return leadFields;
  }

  global override String customRoutingRule(SObject primary, Map<String, SObject> chosenSObjects, String parameter) {
    List<LeanData_Custom_Interface_Setting__c> lcisList = [SELECT Id, Key__c, Value__c From LeanData_Custom_Interface_Setting__c];
    Map<String, String> lcisMap = new Map<String, String>();

    for(LeanData_Custom_Interface_Setting__c lcis : lcisList){
      lcisMap.put(lcis.Key__c, lcis.Value__c);
    }

    if(parameter == 'Existing Subscription for Product?'){
      if(primary.getSObjectType()==Lead.sObjectType){
        Lead candidateLead = (Lead)primary;
        Account acc = (Account)chosenSObjects.get('L2A');

        if(candidateLead.CWS_Product_Intrest__c == null){
          return 'No Subscription Found';
        }

        String productCategory = candidateLead.CWS_Product_Intrest__c;

        Set<String> categorySet = new Set<String>();

        for(String category : lcisMap.keySet()){
          if(productCategory.contains(lcisMap.get(category))){
            cateGorySet.add(category);
          }
        }
        
        List<SBQQ__Subscription__c> subscriptionList = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Account__c = :acc.Id AND SBQQ__Product__r.CWS_Category__c IN :categorySet];

        if(subscriptionList.size() > 0){
            return 'Subscription Exists';
        } else {
            return 'No Subscription Found';
        }
      } else if(primary.getSObjectType()==Contact.sObjectType){
        Contact candidateContact = (Contact) primary;

        if(candidateContact.CWS_Product_Interest__c == null){
          return 'No Subscription Found';
        }

        String productCategory = candidateContact.CWS_Product_Interest__c;

        Set<String> categorySet = new Set<String>();

        for(String category : lcisMap.keySet()){
          if(productCategory.contains(lcisMap.get(category))){
            cateGorySet.add(category);
          }
        }
        
        List<SBQQ__Subscription__c> subscriptionList = [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Account__c = :candidateContact.AccountId AND SBQQ__Product__r.CWS_Category__c IN :categorySet];

        if(subscriptionList.size() > 0){
            return 'Subscription Exists';
        } else {
            return 'No Subscription Found';
        }
      }
    }

    return 'Bad Parameter';
  }

}