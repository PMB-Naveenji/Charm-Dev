@istest
public class EUMIRTriggerHandlerTest1 {
@testSetup
    static void setupData() {
        List<Country__c> countries1 = Test.loadData(Country__c.sObjectType, 'CountriesDataResource');
        Set<String> countryNames = new Set<String>();
        for (Country__c c : countries1) {
            system.debug('====>'+c.Name);
            //countryNames.add(c.Name);
        }
    }

}