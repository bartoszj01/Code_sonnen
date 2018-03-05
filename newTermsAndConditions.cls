/*
* the class receives list of (newly created) Terms and Conditions records from insert trigger. For each contract where the T&Cs are valid, a new record TnCsAcceptance will be created

*/
public with sharing class newTermsAndConditions {
	public void newTermsAndConditions(List<TermsAndConditions__c> tncs) {
	
		//find all TnCsAcc records that are related to the TnCs with the same document type as the new TnC document
		//create new TnCAcceptance

		Set<String> types = new Set<String>(); // types of newly created termd and conditions versions
		List<TnCsAcceptance__c> newAcc = new List<TnCsAcceptance__c>(); // list of TnCsAcceptance to be created with the new version of Terms and conditions
		Set<Contract> contractSet = new Set<Contract>();
		Map<String, Id> mapTypeId = new Map<String, Id>();

		for(TermsAndConditions__c tnc : tncs){
			types.add(tnc.Type__c);
			mapTypeId.put((String) tnc.Type__c, (Id) tnc.Id);
		}

		//List<TnCsAcceptance__c> accList = [SELECT id, Contract__c, TermsAndConditions__c FROM TnCsAcceptance__c WHERE Contract__r.Type__c IN :types];
		List<Contract> cList = [SELECT id FROM Contract WHERE Id IN (SELECT Contract__c FROM TnCsAcceptance__c  WHERE Contract__r.Type__c IN :types)];
		contractSet.addAll(cList);

		List<AggregateResult> arList = [SELECT Contract__c, TermsAndConditions__r.Type__c ty FROM TnCsAcceptance__c WHERE TermsAndConditions__r.Type__c IN :types GROUP BY Contract__c, TermsAndConditions__r.Type__c ];
		for (AggregateResult ar : arList) {
			TnCsAcceptance__c acc = new TnCsAcceptance__c();
			acc.Contract__c = (Id) ar.get('Contract__c');
			acc.TermsAndConditions__c = mapTYpeId.get((String) ar.get('ty'));
			acc.Accepted__c = false;	
			newAcc.add(acc);
		}
		insert newAcc;
	}
}