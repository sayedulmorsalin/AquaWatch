import 'package:flutter/material.dart';

class DataEntry extends StatefulWidget {
  const DataEntry({super.key});

  @override
  State<DataEntry> createState() => _DataEntryState();
}

class _DataEntryState extends State<DataEntry> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Wellcome to AquaWatch",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text("Please enter data what you get from the device ", style: TextStyle(fontSize: 20),)],
          ),

          SizedBox(height: 20,),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter pH of the water',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20,),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter TDS of the water',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20,),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter EC of the water',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20,),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter Salinity of the water',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20,),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter temperature of the water',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20,),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: (){}, child: Text("Submit"))
            ]
          )
        ],
      ),
    );
  }
}
