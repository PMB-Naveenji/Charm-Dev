public class Redirect{
    public Redirect(ApexPages.StandardController controller){
    }
    public PageReference getRedir(){
        PageReference newPage;
        Id regOpinionTaskRTID = [Select Id from Recordtype where Name='Regulatory Opinion Task' Limit 1].Id;
        system.debug('VH Debug0:'+ApexPages.currentPage().getParameters().get('RecordType'));
        if(ApexPages.currentPage().getParameters().get('RecordType')!= NULL && ApexPages.currentPage().getParameters().get('RecordType') == regOpinionTaskRTID){
            system.debug('VH Debug1:'+ApexPages.currentPage().getParameters().get('RecordType'));
            system.debug('VH Debug2:'+ApexPages.currentPage().getParameters().get('retURL'));
            String myString = ApexPages.currentPage().getParameters().get('retURL').remove('/');
            Id myId = Id.valueOf(myString);
            String objName = myId.getSObjectType().getDescribe().getName();
            system.debug('VH Debug3:'+ myId.getSObjectType().getDescribe().getName());
            newPage = Page.RegulatoryOpinionTaskNew;
            return newPage.setRedirect(true);
            //if(objName.contains('MIR')){
                //EU_MIR__c = myId;
            //}
            //else if(objName.contains('MEDDEV')){
                //MDI__c = myId;
            //}
        }
        else if (ApexPages.currentPage().getParameters().get('RecordType') != NULL && ApexPages.currentPage().getParameters().get('RecordType') != regOpinionTaskRTID){
            String hostname = ApexPages.currentPage().getHeaders().get('Host'); 
            String optyURL2 = 'https://'+hostname+'/'+'/a1G/e?nooverride=1';
            pagereference pageref = new pagereference(optyURL2);
            pageref.setredirect(true);
            return pageref;
        }
        else{
            return null;
        }
    }

    private final ApexPages.StandardController controller;
}