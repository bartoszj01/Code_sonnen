@isTest
private class TermsAndConditionsTrigger_test {
	
	@isTest static void test_method_one() {

		List<TermsAndConditions__c> tcl = new List<TermsAndConditions__c>();
		TermsAndConditions__c tc = new TermsAndConditions__c( 
			ExpirationDate__c = Date.today(),
			TnCsText__c = 'text goes here',
			Type__c = 'AGBs eServices',
			Valid__c = true,
			Current__c = true,
			VersionNumber__c = '1.0'
		);
		tcl.add(tc);

			TermsAndConditions__c td = new TermsAndConditions__c( 
			ExpirationDate__c = Date.today(),
			TnCsText__c = 'text goes here',
			Type__c = 'Datenschutzvereinbarung eServices',
			Valid__c = true,
			Current__c = true,
			VersionNumber__c = '1.0'
		);
		tcl.add(td);
		insert tcl;

		//List<Account> acList = new List<Account>();
		Account a = new Account(
			Name = 'Test1'
		);
		insert a;

		Contract c = new Contract(
			AccountId = a.Id,
			Type__c = 'sonnenbatterieCity-DE',
			StartDate = Date.today() - 7
		);
		insert c;

		List<TnCsAcceptance__c> tcAcceptList = new List<TnCsAcceptance__c>();
		TnCsAcceptance__c tncAccept = new TnCsAcceptance__c (
			TermsAndConditions__c = tc.Id,
			Contract__c = c.Id
		);
		tcAcceptList.add(tncAccept);

		TnCsAcceptance__c tncAccept2 = new TnCsAcceptance__c (
			TermsAndConditions__c = td.Id,
			Contract__c = c.Id
		);
		tcAcceptList.add(tncAccept2);

		insert tcAcceptList;

		// insert of of new t&c with current == true
		TermsAndConditions__c te = new TermsAndConditions__c( 
			ExpirationDate__c = Date.today(),
			TnCsText__c = 'text goes here',
			Type__c = 'AGBs eServices',
			Valid__c = true,
			Current__c = true,
			VersionNumber__c = '2.0'
		);
		insert te;

		System.assertEquals(1, [SELECT Id FROM TnCsAcceptance__c WHERE TermsAndConditions__r.Id =  :te.Id ].size());

		TermsAndConditions__c tf = new TermsAndConditions__c( 
			ExpirationDate__c = Date.today(),
			TnCsText__c = 'text goes here',
			Type__c = 'AGBs eServices',
			Valid__c = true,
			Current__c = false,
			VersionNumber__c = '3.0'
		);
		insert tf;

		System.assertEquals(0, [SELECT Id FROM TnCsAcceptance__c WHERE TermsAndConditions__r.Id =  :tf.Id ].size());

		tf.Current__c = true;
		update tf;

		System.assertEquals(1, [SELECT Id FROM TnCsAcceptance__c WHERE TermsAndConditions__r.Id =  :tf.Id ].size());


	}
	
}