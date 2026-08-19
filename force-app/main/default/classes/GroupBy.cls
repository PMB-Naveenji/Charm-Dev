/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : GroupBy.
* @Why   : Groups records by entered 'field' method parameter.
* @When  : 17-MAY-2019.
* @Where : From ComplaintTicketReport class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    17-MAY-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    18-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global with sharing class GroupBy {

	/*
    * @Method       : id.
    * @Description  : Groups records by 'field' parameter.
	* @Invoke       : From ComplaintTicketReport.Generate method.
    * @Return       : Map<Id, List<sObject>>.
    * @Params       : string field, List<sObject> records.
    */
    global static Map<Id, List<sObject> > id(string field, List<sObject> records) {
		Map<Id, List<sObject> > returnMap = new Map<Id, List<sObject> >();
		for (sObject record : records)
		{
			Id key = (Id)record.get(field);
			if (!returnMap.containsKey(key))
				returnMap.put(key, new List<sObject>());
			returnMap.get(key).add(record);
		}
		return returnMap;
	}

	/*
    * @Method       : parentId.
    * @Invoke       : From ComplaintTicketReport.Generate method.
    * @Description  : Groups records by 'field' parameter from 'parents' list.
    * @Return       : Map<Id, List<sObject>>.
    * @Params       : string[] parents, string field, List<sObject> records.
    */
	global static Map<Id, List<sObject> > parentId(string[] parents, string field, List<sObject> records) {
		Map<Id, List<sObject> > returnMap = new Map<Id, List<sObject> >();
		for (sObject record : records)
		{
        	sObject parent = record;
			for (string parentName : parents) {
				parent = parent.getSobject(parentName);
			}
			Id key = (Id)parent.get(field);
			if (!returnMap.containsKey(key))
				returnMap.put(key, new List<sObject>());
			returnMap.get(key).add(record);
		}
		return returnMap;
	}
}