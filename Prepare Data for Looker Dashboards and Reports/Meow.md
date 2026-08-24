# Prepare Data for Looker Dashboards and Reports: Challenge Lab || GSP346  

### This script and guide are provided for the educational purposes to help you understand the lab services and boost your career. Before using the script, please open and review it to familiarize yourself with Google Cloud services.
### Always ensure compliance with Qwiklabs' terms of service and YouTube's community guidelines. The aim is to enhance your learning experience — not to circumvent it.

### Look 1:

```bash
explore: +airports {
     query: ManavYugAI{
      dimensions: [city, state]
      measures: [count]
      filters: [airports.facility_type: "HELIPORT^ ^ ^ ^ ^ ^ ^ "]
    } 
}
```
### Look 2:

```bash
explore: +airports {
    query: ManavYugAI{
      dimensions: [facility_type, state]
      measures: [count]
    }
  }
```
### Look 3:

```bash
explore: +flights {
    query: ManavYugAI{
      dimensions: [aircraft_origin.city, aircraft_origin.state]
      measures: [cancelled_count, count]
    }
}
```

