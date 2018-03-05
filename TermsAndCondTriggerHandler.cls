/*
* Author: Bartosz Jarmolinski
* test class: TermsAndConditionsTrigger_test
* Wrike ticket: AGB Objekt für sonnen Produkte einführen
*
*/
public class TermsAndCondTriggerHandler extends TriggerHandler {

    public override void beforeUpdate() {
    	this.newTermsAndConditions();    	         
    }    
    public override void beforeInsert() {         
    }
    public override void afterInsert() {
    	this.newTermsAndConditions();
    }
    public override void afterUpdate() {
    }

    //the method creates new TnCsAcceptance object if a new Terms and conditions is created and/or Current__c field is set to true
	private void newTermsAndConditions() {
	
		//find all TnCsAcc records that are related to the TnCs with the same document type as the new TnC document
		//create new TnCAcceptance
		List<TermsAndConditions__c> tncs = Trigger.new;
		Set<String> types = new Set<String>(); // types of newly created termd and conditions versions
		List<TnCsAcceptance__c> newAcc = new List<TnCsAcceptance__c>(); // list of TnCsAcceptance to be created with the new version of Terms and conditions
		Set<Contract> contractSet = new Set<Contract>();
		Map<String, Id> mapTypeId = new Map<String, Id>();

		for(TermsAndConditions__c tnc : tncs){
			if(Trigger.isUpdate){
				TermsAndConditions__c oldObj = (TermsAndConditions__c)Trigger.oldMap.get(tnc.Id);
				if(Trigger.isUpdate && tnc.Current__c == true && oldObj.Current__c == false) {
					types.add(tnc.Type__c);
 					mapTypeId.put((String) tnc.Type__c, (Id) tnc.Id);					
				}				
			}
			if(Trigger.isInsert && tnc.Current__c == true){
				types.add(tnc.Type__c);
 				mapTypeId.put((String) tnc.Type__c, (Id) tnc.Id);
			}
		}
		// uncheck Current__c on every other TermsAndConditions of the given type
		List<TermsAndConditions__c> oldTncs = [SELECT id, Current__c FROM TermsAndConditions__c WHERE Type__c IN :types AND Id NOT IN: Trigger.newMap.keySet()];
		for(TermsAndConditions__c t : oldTncs) {
			t.Current__c = false;
		}
		update oldTncs;

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