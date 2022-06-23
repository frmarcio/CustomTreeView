# CustomTreeView
Please follows the example for using the current implementation along the attribute "deserializedSoqls":
[
	{
		"soql": "select Id, name, parentroleid from userrole  where parentroleid =null",
		"pickupfields": "Id",
		"sendpickupfieldsAs": "parentroleid",
		"displayfields": "name",
		"showCheckbox": false,
		"canExpand": true,
		"distinctValues": true
	},
	{
		"soql": "select Id, name, parentroleid from userrole  where @filter ",
		"pickupfields": "Id",
		"sendpickupfieldsAs": "parentroleid",
		"displayfields": "name",
		"showCheckbox": false,
		"canExpand": true,
		"distinctValues": false,
		"recursive": true
	}    
]
