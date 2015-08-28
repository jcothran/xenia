


---

# Header/Footer #

  * News items?
  * Email/phone contact info?
  * changes? - about page
  * changes? - partnership page

# Homepage #

  * possible upcoming logo, color styling changes
  * search bar not currently functional
  * site 'feedback' tab not functional


---

# Learn #

  * need content verbiage for 'Habitat Conservation'


---

# Catalog #

  * Jesse
    * 'view' opens to layer zoom/extent(fix should be including layer extent info in config file - bookmark field)
    * (marco also) 'view' opens in active tab

  * (marco also) - catalog hierarchical listing - the default catalog listing is 'flat' alphabetical layer name ordering within each theme. User requested the default listing to be similar to 'visualize' layer listing with collapsible sections and preservation of layer sub-groupings. My suggestion if this were the case would be to also add a 'flat' listing option as well to allow toggling between a hierarchical and flat listing of layers and associated links.


---

# Visualize #

  * still working to display up the **raw** bathmetry data and CVI (Coastal Vulnerability Index) layers.
  * some layer names are acronyms and need to be renamed to something better understood and less cryptic.
  * Missing legends - these are the legends that don't support the REST legend request:
    * All Restrictions
    * Black Sea Bass Pots Restrictions
    * Bottom Longlines Restrictions
    * Commercial Fishing Seasons and Closures
    * Federal OCS Administrative Boundaries
    * Fish Traps Restrictions
    * Limit of OCSLA \u20188(g)\u2019 zone
    * OCS Lease Blocks
    * OCS Protraction Diagrams
    * Octocoral Gear Restrictions
    * Recreational Fishing Seasons and Closures
    * Roller Rig Trawls Restrictions
    * Sargassum Restrictions
    * Submerged Land Acts Boundary

  * layer units?
    * ports

  * (marco also) - description text overlays basemap text - difficult to read - maybe upwards styling/spacing fix on description overlay

  * map extents
    * initial map extent shifted southward, focus on 4 state region
    * query extents limited to GSAA 4-state region

  * query/identify tool - when user clicks on the map, info is displayed about that point on the map
    * for Marco this is done using UTFGrid which is a pre-processing step on the data layers to grid-subset and provide a client-cached summary file(JSON) that is downloaded alongside the map image.  This functionality also supports mouse 'hover' since the summary grid data is resident on the client.
    * for our initial approach, we would be using ESRI's Query and Geoprocessing API's to make a dynamic web services request(on mouse click) against the remote server associated with the data layer
    * we could assume all 'active' layers should be queried or allow a layer selection method(checkbox?) for layers that should be queried
    * query info displayed as a pop-up?