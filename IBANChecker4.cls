/*
* @Author: Bartosz Jarmolinski
* @Created: 28/02/2018
* the class queues callouts to iban-rechner service in order to obtain additional info about the bank and bank account
* the code is tested by IBANChecker2_Test
*/
public class IBANChecker4 implements Queueable, Database.AllowsCallouts{
    
    private List<BankData__c> bdList {get; set;}
    
    public IBANChecker4(List<BankData__c> bdList) {
        this.bdList = bdList;
    }
    
    public void execute(QueueableContext context) {
        checkIBAN(bdList);
        System.debug(bdList.size());
    }
    
    public static void checkIBAN(List<BankData__c> bdList) {
        System.debug(bdList);
        System.debug(bdList.size());

        //requery the records to be updated to avoid collection ready-only error
        Set<Id> bankDataIds = new Set<Id>();
        for(BankData__c bd : bdList) {
            bankDataIds.add(bd.Id);            
        }
        List<BankData__c> bdListQueried = [SELECT Id, IBAN__c, BankName__c, BankAddress__c, BankCode__c, BIC__c, IBANCheckResult__c, Branch__c, IBANValidated__c, Balance__c FROM BankData__c WHERE Id IN:bankDataIds ];
        List<BankData__c> newBdList = new List<BankData__c>();
        List<BankDataSetting__mdt> bds = [SELECT Username__c, Password__c, Url__c FROM BankDataSetting__mdt WHERE MasterLabel = 'TriggerSettings'];

        while(bdListQueried.size() > 0) {

            System.debug(Limits.getLimitQueueableJobs() > Limits.getQueueableJobs());
            if(Limits.getLimitQueueableJobs() > Limits.getQueueableJobs() ) {

                System.debug(bdListQueried);
                BankData__c bn =  bdListQueried.remove(0);
                System.debug(bn);

                //construct http callout
                String endpointUrl = bds[0].Url__c + bn.IBAN__c;

                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpointUrl);
                req.setMethod('GET');
                
                Blob headerValue = Blob.valueOf(bds[0].Username__c +':'+ bds[0].Password__c); 
                String authorizationHeader = 'Basic '+ EncodingUtil.base64Encode(headerValue);

                req.setHeader('Authorization', authorizationHeader);
                
                HttpResponse res = new HttpResponse();
                if(Test.isRunningTest()) {

                    String body = '{ "iban": "IE92BOFI90001710027952", "result": "passed", "return_code": 0, "checks": [ "length", "bank_code", "account_number", "iban_checksum" ], "bic_candidates": [ { "bic": "BOFIIE2DXXX", "zip": "", "city": "", "wwwcount": 0, "sampleurl": "" } ], "all_bic_candidates": [ { "bic": "BOFIIE2DXXX", "zip": "", "city": "", "wwwcount": 0, "sampleurl": "" } ], "country": "IE", "bank_code": "900017", "bank": "Bank of Ireland", "bank_address": "c/o 2 College Green Dublin 2 ", "bank_street": "c/o 2 College Green", "bank_city": "Dublin", "bank_state": "", "bank_postal_code": "2", "bank_url": "", "branch": "", "branch_code": "", "balance": 9999 }';
                    SingleRequestMock mockResponse = new SingleRequestMock(200, 'Completed', body, null);
                    res = mockResponse.respond(req);

                }                
                else {
                    res = h.send(req);
                }
                
                System.debug(res.getStatusCode());
                if(res.getStatusCode() == 200) {

                    String body = res.getBody();
                    System.debug(body);
                    wrapperClass wrap = (wrapperClass) JSON.deserialize(body, wrapperClass.class);
                    System.debug(wrap);
        
                    Map<String, String> bicData = wrap.bic_candidates[0];
                    System.debug(bicData.get('bic'));
        
                    bn.BankName__c = wrap.bank;
                    bn.BankAddress__c = wrap.bank_address;
                    bn.BankCode__c = wrap.bank_code;
                    bn.BIC__c = wrap.bic_candidates[0].get('bic');
                    bn.IBANCheckResult__c = wrap.result;
                    bn.Branch__c = wrap.branch;
                    bn.IBANValidated__c = Datetime.now();
                    bn.Balance__c = wrap.balance;
                    
                    newBdList.add(bn);
                }
            }
            else {
                break;
            }
        }

        update newBdList;

        if(bdListQueried.size() > 0) {
            IBANChecker4 q = new IBANChecker4(bdListQueried);
            System.enqueueJob(q);
        }
    }
    class wrapperClass {
        String iban;
        String result;
        String bank;
        List<Map<String, String>> bic_candidates;
        String bank_code;
        String bank_address;
        String branch;
        String branch_code;
        Decimal balance;
    }
}