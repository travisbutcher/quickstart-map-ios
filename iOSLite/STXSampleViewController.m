//
//  STXSampleViewController.m
//  iOSLite
//
//  Created by Nicholas Furness on 5/8/12.
//  Copyright (c) 2012 ESRI. All rights reserved.
//

#import "STXSampleViewController.h"
#import "STXPortalItemPickerView.h"

#import "STXHelper.h"

#import "AGSMapView+GeoServices.h"

#import	"AGSMapView+Navigation.h"
#import "AGSMapView+Basemaps.h"
#import "AGSMapView+Graphics.h"
#import "AGSMapView+RouteDisplay.h"

#import "STXGeoServices.h"

#import "AGSMapView+GeneralUtilities.h"
#import "AGSPoint+GeneralUtilities.h"

#import "UIApplication+AppDimensions.h"

#import "STXBasemapPickerView.h"
#import "STXBasemapDetailsViewController.h"
#import <objc/runtime.h>

typedef enum 
{
    STXSampleAppStateBasemaps,
    STXSampleAppStateGeolocation,
    STXSampleAppStateGraphics,
    STXSampleAppStateGraphics_Editing,
    STXSampleAppStateFindPlace,
    STXSampleAppStateFindAddress,
	STXSampleAppStateDirections,
    STXSampleAppStateDirections_WaitingForRouteStart,
    STXSampleAppStateDirections_WaitingForRouteEnd
}
STXSampleAppState;

#define kSTXGetAddressReasonKey @"FindAddressReason"
#define kSTXGetAddressReasonRouteStart @"RouteStartPoint"
#define kSTXGetAddressReasonRouteEnd @"RouteEndPoint"
#define kSTXGetAddressReasonReverseGeocodeForPoint @"FindAddressFunction"

@interface STXSampleViewController () <AGSPortalItemDelegate, AGSMapViewTouchDelegate, AGSRouteTaskDelegate, UISearchBarDelegate, AGSLocatorDelegate, UIWebViewDelegate, STXBasemapPickerDelegate>

// General UI
@property (weak, nonatomic) IBOutlet UIToolbar *functionToolBar;
@property (weak, nonatomic) IBOutlet UIView *routingPanel;
@property (weak, nonatomic) IBOutlet UIView *findAddressPanel;
@property (weak, nonatomic) IBOutlet UISearchBar *findAddressSearchBar;
@property (weak, nonatomic) IBOutlet UIView *findPlacePanel;
@property (weak, nonatomic) IBOutlet UIView *basemapInfoPanel;
@property (weak, nonatomic) IBOutlet UIView *geolocationPanel;
@property (weak, nonatomic) IBOutlet UIView *graphicsPanel;

// Basemaps
@property (weak, nonatomic) IBOutlet STXBasemapPickerView *basemapsPicker;

@property (strong, nonatomic) NSMutableArray *basemapVCs;

@property (nonatomic, retain) AGSPortalItem *currentPortalItem;

//Graphics UI
@property (weak, nonatomic) IBOutlet UIButton *graphicButton;
@property (weak, nonatomic) IBOutlet UIButton *clearPointsButton;
@property (weak, nonatomic) IBOutlet UIButton *clearLinesButton;
@property (weak, nonatomic) IBOutlet UIButton *clearPolysButton;
// Edit Graphics UI
@property (weak, nonatomic) IBOutlet UIToolbar *editGraphicsToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *undoEditGraphicsButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *redoEditGraphicsButton;
- (IBAction)doneEditingGraphic:(id)sender;
- (IBAction)cancelEditingGraphic:(id)sender;
- (IBAction)undoEditingGraphic:(id)sender;
- (IBAction)redoEditingGraphic:(id)sender;
- (IBAction)zoomToEditingGeometry:(id)sender;

- (IBAction)newPtGraphic:(id)sender;
- (IBAction)newLnGraphic:(id)sender;
- (IBAction)newPgGraphic:(id)sender;
- (IBAction)newMultiPtGraphic:(id)sender;



// Routing UI
@property (weak, nonatomic) IBOutlet UIButton *routeStartButton;
@property (weak, nonatomic) IBOutlet UIButton *routeEndButton;
@property (weak, nonatomic) IBOutlet UILabel *routeStartLabel;
@property (weak, nonatomic) IBOutlet UILabel *routeEndLabel;
@property (weak, nonatomic) IBOutlet UIButton *clearRouteButton;
// Routing Properties
@property (nonatomic, strong) AGSPoint *routeStartPoint;
@property (nonatomic, strong) AGSPoint *routeEndPoint;
@property (nonatomic, retain) NSString *routeStartAddress;
@property (nonatomic, retain) NSString *routeEndAddress;
@property (nonatomic, retain) AGSRouteTaskResult *routeResult;


// Geolocation UI
@property (weak, nonatomic) IBOutlet UILabel *findScaleLabel;

// Non UI Properties
@property (assign) STXBasemapType currentBasemapType;
@property (assign) BOOL uiControlsVisible;

@property (assign) STXSampleAppState currentState;

@property (nonatomic, assign) NSUInteger findScale;

@property (nonatomic, assign) CGSize keyboardSize;

// Actions
- (IBAction)addGraphics:(id)sender;

- (IBAction)clearPoints:(id)sender;
- (IBAction)clearLines:(id)sender;
- (IBAction)clearPolygons:(id)sender;

- (IBAction)clearRoute:(id)sender;

- (IBAction)findMe:(id)sender;
- (IBAction)findScaleChanged:(id)sender;
- (IBAction)zoomToLevel:(id)sender;

- (IBAction)functionChanged:(id)sender;

- (IBAction)toFromTapped:(id)sender;
@end

@implementation STXSampleViewController
@synthesize editGraphicsToolbar = _editGraphicsToolbar;
@synthesize undoEditGraphicsButton = _undoEditGraphicsButton;
@synthesize redoEditGraphicsButton = _redoEditGraphicsButton;
@synthesize basemapInfoPanel = _infoView;
@synthesize geolocationPanel = _geolocationPanel;
@synthesize graphicsPanel = _graphicsPanel;
@synthesize basemapsPicker = _basemapsPicker;
@synthesize graphicButton = _graphicButton;
@synthesize clearPointsButton = _clearPointsButton;
@synthesize clearLinesButton = _clearLinesButton;
@synthesize clearPolysButton = _clearPolysButton;
@synthesize routingPanel = _routingPanel;
@synthesize findAddressPanel = _findAddressPanel;
@synthesize findAddressSearchBar = _findAddressSearchBar;
@synthesize findPlacePanel = _findPlacePanel;
@synthesize routeStartLabel = _routeStartLabel;
@synthesize routeEndLabel = _routeStopLabel;
@synthesize clearRouteButton = _clearRouteButton;

@synthesize mapView = _mapView;

@synthesize currentPortalItem = _currentPortalItem;
@synthesize currentBasemapType = _currentBasemapType;

@synthesize uiControlsVisible = _uiControlsVisible;

@synthesize currentState = _currentState;

@synthesize routeStartPoint = _routeStartPoint;
@synthesize routeEndPoint = _routeEndPoint;
@synthesize routeStartAddress = _routeStartAddress;
@synthesize routeEndAddress = _routeEndAddress;

@synthesize findScaleLabel = _findScaleLabel;
@synthesize functionToolBar = _functionToolBar;
@synthesize routeStartButton = _routeStartButton;
@synthesize routeEndButton = _routeStopButton;

@synthesize routeResult = _routeResult;

@synthesize findScale = _findScale;

@synthesize basemapVCs = _basemapVCs;

@synthesize keyboardSize = _keyboardSize;


#define kSTXApplicationLocFromState @"ButtonState"

#pragma mark - Initialization Methods

- (void)initUI
{
	// Track the application state
    self.currentState = STXSampleAppStateBasemaps;

    // Store some state on the UI so that we can track when the user is placing points for routing.
    objc_setAssociatedObject(self.routeStartButton, kSTXApplicationLocFromState, [NSNumber numberWithBool:NO], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self.routeEndButton, kSTXApplicationLocFromState, [NSNumber numberWithBool:NO], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // When we geolocate, what scale level to zoom the map to?
    self.findScale = 13;
    
    // Go through all the various UI component views, hide them and then place them properly
    // in the UI window so that they'll fade in and out properly.
    for (UIView *v in [self allUIViews]) {
        v.alpha = 0;
        v.hidden = YES;
        v.frame = [self getUIFrameWhenHidden:v];
    }

    // And show the UI by default. Note, at present the UI is always visible.
    self.uiControlsVisible = YES;

    // We want to update the UI when the basemap is changed, so register our interest in a couple
    // of events.
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(basemapDidChange:)
												 name:kSTXNotification_BasemapDidChange
											   object:self.mapView];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(basemapSelected:)
//												 name:kSTXNotification_BasemapSelected
//											   object:nil];
	
	// We need to re-arrange the UI when the keyboard displays and hides, so let's find out when that happens.
	self.keyboardSize = CGSizeZero;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // Set up the map UI a little.
    self.mapView.wrapAround = YES;
    self.mapView.touchDelegate = self;
    
    self.routeStartButton.layer.cornerRadius = 5;
    self.routeEndButton.layer.cornerRadius = 5;
    self.clearRouteButton.layer.cornerRadius = 4;
}

#pragma mark - UIView Events

- (void)viewDidLoad
{
    [super viewDidLoad];

	[self initUI];

    // Initialize our property for tracking the current basemap type.
    self.currentBasemapType = STXBasemapTypeTopographic;
	
	[self populateForDefaultBasemaps];
    
	// Set up our map with a basemap, and jump to a location and scale level.
    [self.mapView setBasemap: self.currentBasemapType];
    [self.mapView centerAtLat:40.7302 Long:-73.9958 withScaleLevel:13];
//    AGSPoint *nyc = [AGSPoint pointFromLat:40.7302 Long:-73.9958];
//    [self.mapView centerAtPoint:nyc withScaleLevel:0];
//    [self.mapView centerAtLat:40.7302 Long:-73.9958];
//    [self.mapView zoomToLevel:7];
//    [self.mapView centerAtMyLocation];
//    [self.mapView centerAtMyLocationWithScaleLevel:15];

	[self initForRouting];
	
	// And let me know when it finds points for an address.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotCandidatesForAddress:)
                                                 name:kSTXGeoServicesNotification_PointsFromAddress_OK
                                               object:self.mapView.geoServices];
}

- (void)viewDidUnload
{
    [self setMapView:nil];
    [self setBasemapInfoPanel:nil];
    [self setGraphicButton:nil];
    [self setClearPointsButton:nil];
    [self setClearLinesButton:nil];
    [self setClearPolysButton:nil];
    [self setRoutingPanel:nil];
    [self setRouteStartLabel:nil];
    [self setRouteEndLabel:nil];
    [self setFindScaleLabel:nil];
    [self setFunctionToolBar:nil];
    [self setFindAddressPanel:nil];
    [self setFindPlacePanel:nil];
    [self setGeolocationPanel:nil];
    [self setGraphicsPanel:nil];
    [self setEditGraphicsToolbar:nil];
    [self setUndoEditGraphicsButton:nil];
    [self setRedoEditGraphicsButton:nil];
    [self setRouteStartButton:nil];
    [self setRouteEndButton:nil];
    [self setClearRouteButton:nil];
	[self setFindAddressSearchBar:nil];
	[self setBasemapsPicker:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - AGSMapView Events

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint graphics:(NSDictionary *)graphics
{
    NSLog(@"Clicked on map!");
    switch (self.currentState) {
        case STXSampleAppStateGraphics:
            if (graphics.count > 0)
            {
                // The user selected a graphic. Let's edit it.
                [self.mapView editGraphicFromMapViewDidClickAtPoint:graphics];
                self.currentState = STXSampleAppStateGraphics_Editing;
            }
            break;

        case STXSampleAppStateDirections_WaitingForRouteStart:
            [self didTapStartPoint:mapPoint];
            break;
            
        case STXSampleAppStateDirections_WaitingForRouteEnd:
            [self didTapEndPoint:mapPoint];
            break;
            
        case STXSampleAppStateFindAddress:
            [self didTapToReverseGeocode:mapPoint];
            break;
            
        default:
            NSLog(@"Click on %d graphics", graphics.count);
            for (id key in graphics.allKeys) {
                NSLog(@"Graphic '%@' = %@", key, [graphics objectForKey:key]);
            }
            break;
    }
}

# pragma mark - KVO Events

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"KeyPath: %@", keyPath);
}

#pragma mark - Keyboard Events

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSLog(@"Keyboard will show: %@", NSStringFromCGSize(self.keyboardSize));
    [self updateUIDisplayState:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardSize = CGSizeZero;
    [self updateUIDisplayState:notification];
}

#pragma mark - UI Position and size

- (CGPoint) getUIComponentOrigin
{
    CGRect topFrame = self.functionToolBar.frame;
    CGPoint newOrigin = CGPointMake(topFrame.origin.x, topFrame.origin.y + topFrame.size.height);
    return newOrigin;
}

- (CGRect) getUIFrame:(UIView *)viewToDisplay
{
    return [self getUIFrameWhenHidden:viewToDisplay
                       forOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (CGRect) getUIFrame:(UIView *)viewToDisplay forOrientation:(UIInterfaceOrientation)orientation
{
    CGRect screenFrame = [UIApplication frameInOrientation:orientation];
    CGRect viewFrame = viewToDisplay.frame;
	
    double keyboardHeight = self.keyboardSize.height;
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        // Why? WHY!!!? But OK. If I have to.
        keyboardHeight = self.keyboardSize.width;
    }
	//    NSLog(@"Screen Height: %f, view Height: %f, keyboard Height: %f", screenFrame.size.height, viewFrame.size.height, keyboardHeight);
    CGPoint origin = CGPointMake(screenFrame.origin.x, screenFrame.size.height - viewFrame.size.height - keyboardHeight);
	//    NSLog(@"Screen: %@", NSStringFromCGRect(screenFrame));
    CGRect newFrame = CGRectMake(origin.x, origin.y, viewFrame.size.width, viewFrame.size.height);
	//    NSLog(@"   New: %@", NSStringFromCGRect(newFrame));
    return newFrame;
}

- (CGRect) getUIFrameWhenHidden:(UIView *)viewToHide
{
    return [self getUIFrameWhenHidden:viewToHide
                       forOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (CGRect) getUIFrameWhenHidden:(UIView *)viewToHide forOrientation:(UIInterfaceOrientation)orientation
{
    CGRect screenFrame = [UIApplication frameInOrientation:orientation];
    CGPoint origin = CGPointMake(screenFrame.origin.x, screenFrame.size.height);
    CGSize viewSize = viewToHide.frame.size;
    // Position it to the left of the screen.
    CGRect newFrame = CGRectMake(origin.x, origin.y, viewSize.width, viewSize.height);
    return newFrame;
}

#pragma mark - Application State

- (STXSampleAppState)currentState
{
    return _currentState;
}

- (void) setCurrentState:(STXSampleAppState)currentState
{
    _currentState = currentState;
    
    switch (_currentState) {
        case STXSampleAppStateDirections_WaitingForRouteStart:
            self.routeStartLabel.text = @"Tap a point on the map…";
			self.routeStartButton.selected = YES;
			self.routeEndButton.selected = NO;
            break;
        case STXSampleAppStateDirections_WaitingForRouteEnd:
            self.routeEndLabel.text = @"Tap a point on the map…";
			self.routeEndButton.selected = YES;
			self.routeStartButton.selected = NO;
            break;
            
        case STXSampleAppStateGraphics_Editing:
            for (UIBarButtonItem *buttonItem in self.editGraphicsToolbar.items) {
                buttonItem.enabled = YES;
            }
            [self setUndoRedoButtonStates];
            [self listenToEditingUndoManager];
            self.mapView.showMagnifierOnTapAndHold = YES;
            break;
        case STXSampleAppStateGraphics:
            for (UIBarButtonItem *buttonItem in self.editGraphicsToolbar.items) {
                buttonItem.enabled = NO;
            }
            self.mapView.showMagnifierOnTapAndHold = NO;
            break;
            
        default:
            break;
    }
    
    [self.view endEditing:YES];

    [self updateUIDisplayState];
}

#pragma mark - UI Function Selection

- (IBAction)functionChanged:(id)sender {
    UISegmentedControl *seg = sender;
    switch (seg.selectedSegmentIndex) {
        case 0:
            self.currentState = STXSampleAppStateBasemaps;
            break;
        case 1:
            self.currentState = STXSampleAppStateGeolocation;
            break;
        case 2:
            self.currentState = STXSampleAppStateGraphics;
            break;
        case 3:
            self.currentState = STXSampleAppStateFindPlace;
            break;
        case 4:
            self.currentState = STXSampleAppStateFindAddress;
            break;
        case 5:
            self.currentState = STXSampleAppStateDirections;
            break;
        default:
            NSLog(@"Set state to %d", seg.selectedSegmentIndex);
            break;
    }
}

- (NSMutableArray *)allUIViews
{
    NSMutableArray *uiViews = [NSMutableArray arrayWithObjects:self.routingPanel,
                               self.basemapsPicker,
                               self.geolocationPanel,
                               self.findAddressPanel,
                               self.findPlacePanel,
                               self.graphicsPanel, nil];
    return uiViews;
}

- (UIView *) getViewToShow
{
    UIView *viewToShow = nil;
    
    switch (self.currentState) {
        case STXSampleAppStateBasemaps:
            viewToShow = self.basemapsPicker;
            break;
        case STXSampleAppStateDirections:
        case STXSampleAppStateDirections_WaitingForRouteStart:
        case STXSampleAppStateDirections_WaitingForRouteEnd:
            viewToShow = self.routingPanel;
            break;
        case STXSampleAppStateFindAddress:
            viewToShow = self.findAddressPanel;
            break;
        case STXSampleAppStateFindPlace:
            viewToShow = self.findPlacePanel;
            break;
        case STXSampleAppStateGeolocation:
            viewToShow = self.geolocationPanel;
            break;
        case STXSampleAppStateGraphics:
        case STXSampleAppStateGraphics_Editing:
            viewToShow = self.graphicsPanel;
            break;
    }
    
    return viewToShow;
}

- (NSArray *) getViewsToHide
{
    NSMutableArray *views = [self allUIViews];
    UIView *viewToDisplay = [self getViewToShow];
    [views removeObject:viewToDisplay];
    return views;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateUIDisplayStateOverDuration:0];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateUIDisplayStateOverDuration:duration forOrientation:toInterfaceOrientation];
}

- (void)updateUIDisplayState
{
    [self updateUIDisplayStateOverDuration:0.4];
}

- (void)updateUIDisplayState:(NSNotification *)keyboardNotification
{
    if (keyboardNotification)
    {
        NSTimeInterval animationDuration;
        NSValue *value = [keyboardNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
        [value getValue:&animationDuration];
        [self updateUIDisplayStateOverDuration:animationDuration];
    }
    else
    {
        [self updateUIDisplayState];
    }
}

- (void)updateUIDisplayStateOverDuration:(NSTimeInterval)animationDuration
{
    [self updateUIDisplayStateOverDuration:animationDuration
                            forOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)updateUIDisplayStateOverDuration:(NSTimeInterval)animationDuration forOrientation:(UIInterfaceOrientation)orientation
{
    UIView *viewToShow = [self getViewToShow];
    NSArray *viewsToHide = [self getViewsToHide];
    
    // If the view is already visible, then we don't need to update...
    BOOL needToChange = YES;//viewToShow.hidden == NO;
    
    if (needToChange)
    {
        // Animate out the old views and animate in the new view
        UIView *viewToAnimateOut = nil;
        
        for (UIView *viewCandidate in viewsToHide) {
            if (!viewCandidate.hidden)
            {
                viewToAnimateOut = viewCandidate;
                break;
            }
        }
        
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        viewToShow.hidden = NO;
        [UIView animateWithDuration:animationDuration
                         animations:^{
                             viewToShow.alpha = 1;
                             viewToAnimateOut.alpha = 0;
                             viewToShow.frame = [self getUIFrame:viewToShow forOrientation:orientation];
                             viewToAnimateOut.frame = [self getUIFrameWhenHidden:viewToAnimateOut ];
                         }
                         completion:^(BOOL finished) {
                             viewToAnimateOut.hidden = YES;
                             [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                         }];
    }
}

- (BOOL)uiControlsVisible
{
    return _uiControlsVisible;
}

- (void)setUiControlsVisible:(BOOL)uiControlsVisible
{
    _uiControlsVisible = uiControlsVisible;
    [self updateUIDisplayState];
}

#pragma mark - Undo/Redo

- (void) setUndoRedoButtonStatesForUndoManager:(NSUndoManager *)um
{
    if (um)
    {
        self.undoEditGraphicsButton.enabled = um.canUndo;
        self.redoEditGraphicsButton.enabled = um.canRedo;
    }
}

- (void) setUndoRedoButtonStates
{
    [self setUndoRedoButtonStatesForUndoManager:[self.mapView getUndoManagerForGraphicsEdits]];
}

- (void) editUndoRedoChanged:(NSNotification *)notification
{
    NSUndoManager *um = notification.object;
    [self setUndoRedoButtonStatesForUndoManager:um];
}

- (void)listenToEditingUndoManager
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"NSUndoManagerDidCloseUndoGroupNotification" 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"NSUndoManagerDidUndoChangeNotification" 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"NSUndoManagerDidRedoChangeNotification" 
                                                  object:nil];
    
    NSUndoManager *um = [self.mapView getUndoManagerForGraphicsEdits];
    if (um)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(editUndoRedoChanged:)
                                                     name:@"NSUndoManagerDidCloseUndoGroupNotification"
                                                   object:um];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(editUndoRedoChanged:)
                                                     name:@"NSUndoManagerDidUndoChangeNotification"
                                                   object:um];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(editUndoRedoChanged:)
                                                     name:@"NSUndoManagerDidRedoChangeNotification"
                                                   object:um];
    }
}

#pragma mark - Basemap Selection

// Populate the PortalItemViewer with items based off our Basemap List
- (void) populateForDefaultBasemaps
{
	self.basemapsPicker.basemapDelegate = self;
	self.basemapsPicker.basemapType = self.currentBasemapType;
}

- (void)basemapSelected:(STXBasemapType)basemapType
{
	self.currentBasemapType = basemapType;
	self.currentPortalItem = self.basemapsPicker.currentPortalItem;
	[self.mapView setBasemap:basemapType];
}

- (STXBasemapType)currentBasemapType
{
    return _currentBasemapType;
}

- (void)setCurrentBasemapType:(STXBasemapType)currentBasemapType
{
    _currentBasemapType = currentBasemapType;
	
	NSString *portalItemID = [STXHelper getBasemapWebMap:_currentBasemapType].portalItem.itemId;
	
	self.basemapsPicker.currentPortalItemID = portalItemID;
}

- (void)basemapDidChange:(NSNotification *)notification
{
    AGSPortalItem *pi = [notification.userInfo objectForKey:@"PortalItem"];
    STXBasemapType basemapType = [(NSNumber *)[notification.userInfo objectForKey:@"BasemapType"] intValue];
    self.currentBasemapType = basemapType;
    if (pi)
    {
        self.currentPortalItem = pi;
    }
	
	self.basemapsPicker.currentPortalItemID = pi.itemId;
}

#pragma mark - Basemap Info

- (void)basemapsPickerDidTapInfoButton:(id)basemapsPicker
{
	if (basemapsPicker == self.basemapsPicker)
	{
		// It's us.
		[self performSegueWithIdentifier:@"showBasemapInfo" sender:self];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // If the Info Modal View is about to be shown, tell it what PortalItem we're showing.
    if ([segue.identifier isEqualToString:@"showBasemapInfo"])
    {
        STXBasemapDetailsViewController *destVC = segue.destinationViewController;
        destVC.portalItem = self.currentPortalItem;
    }
}

#pragma mark - Graphics

- (IBAction)addGraphics:(id)sender {
    [self.mapView addPointAtLat:40.7302 Long:-73.9958];
    [self.mapView addLineFromPoints:[NSArray arrayWithObjects:[AGSPoint pointFromLat:40.7302 Long:-73.9958],
									 [AGSPoint pointFromLat:41.0 Long:-73.9], nil]];
    [self.mapView addPolygonFromPoints:[NSArray arrayWithObjects:[AGSPoint pointFromLat:40.7302 Long:-73.9958],
										[AGSPoint pointFromLat:40.85 Long:-73.65],
										[AGSPoint pointFromLat:41.0 Long:-73.7],nil]];
}

- (IBAction)newPtGraphic:(id)sender {
    [self.mapView createAndEditNewPoint];
    self.currentState = STXSampleAppStateGraphics_Editing;
}

- (IBAction)newLnGraphic:(id)sender {
    [self.mapView createAndEditNewLine];
    self.currentState = STXSampleAppStateGraphics_Editing;
}

- (IBAction)newPgGraphic:(id)sender {
    [self.mapView createAndEditNewPolygon];
    self.currentState = STXSampleAppStateGraphics_Editing;
}

- (IBAction)newMultiPtGraphic:(id)sender {
    [self.mapView createAndEditNewMultipoint];
    self.currentState = STXSampleAppStateGraphics_Editing;
}

- (IBAction)clearPoints:(id)sender {
    [self.mapView clearGraphics:STXGraphicsLayerTypePoint];
}

- (IBAction)clearLines:(id)sender {
    [self.mapView clearGraphics:STXGraphicsLayerTypePolyline];
}

- (IBAction)clearPolygons:(id)sender {
    [self.mapView clearGraphics:STXGraphicsLayerTypePolygon];
}

- (IBAction)doneEditingGraphic:(id)sender {
    [self.mapView saveCurrentEdit];
    self.currentState = STXSampleAppStateGraphics;
}

- (IBAction)cancelEditingGraphic:(id)sender {
    [self.mapView cancelCurrentEdit];
    self.currentState = STXSampleAppStateGraphics;
}

- (IBAction)undoEditingGraphic:(id)sender {
    [[self.mapView getUndoManagerForGraphicsEdits] undo];
}

- (IBAction)redoEditingGraphic:(id)sender {
    [[self.mapView getUndoManagerForGraphicsEdits] redo];
}

- (IBAction)zoomToEditingGeometry:(id)sender {
    AGSGeometry *editGeom = [self.mapView getCurrentEditGeometry];
    if (editGeom)
    {
        [self.mapView zoomToGeometry:editGeom withPadding:25 animated:YES];
    }
}

#pragma mark - Geocoding
- (void) didGetAddressFromPoint:(NSNotification *)notification
{
	NSDictionary *userInfo = notification.userInfo;
	NSOperation *op = [userInfo objectForKey:kSTXGeoServicesNotification_WorkerOperationKey];
	
	if (op)
	{
		AGSAddressCandidate *candidate = [userInfo objectForKey:kSTXGeoServicesNotification_AddressFromPoint_AddressCandidateKey];
		
		NSDictionary *ad = candidate.address;
		NSString *street = [ad objectForKey:kSTXAddressCandidateAddressField];
		if (street != (id)[NSNull null])
		{
			street = [NSString stringWithFormat:@"%@, ", street];
		}
		else {
			street = @"";
		}
		NSString *address = [NSString stringWithFormat:@"%@%@, %@ %@",
							 street,
							 [ad objectForKey:kSTXAddressCandidateCityField],
							 [ad objectForKey:kSTXAddressCandidateStateField],
							 [ad objectForKey:kSTXAddressCandidateZipField]];
		
		// We're only interested in Reverse Geocodes that happened as a result of
		// start or end points of the route being clicked...
		NSString *source = objc_getAssociatedObject(op, kSTXGetAddressReasonKey);
		if (source)
		{
			// OK, this is something we requested and so we should be able to work
			// out what to do with it.
			
			if ([source isEqualToString:kSTXGetAddressReasonRouteStart])
			{
				self.routeStartPoint = candidate.location;
				self.routeStartAddress = address;
			}
			else if ([source isEqualToString:kSTXGetAddressReasonRouteEnd])
			{
				self.routeEndPoint = candidate.location;
				self.routeEndAddress = address;
			}
			else if ([source isEqualToString:kSTXGetAddressReasonReverseGeocodeForPoint])
			{
				self.findAddressSearchBar.text = address;
			}
		}
	}
}

- (void) didFailToGetAddressFromPoint:(NSNotification *)notification
{
	NSError *error = [notification.userInfo objectForKey:kSTXGeoServicesNotification_ErrorKey];
	NSLog(@"Failed to get address for location: %@", error);
}

#pragma mark - Routing

- (void)initForRouting
{
	// Let me know when the Geoservices object finds an address for a point.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didGetAddressFromPoint:)
												 name:kSTXGeoServicesNotification_AddressFromPoint_OK
											   object:self.mapView.geoServices];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didFailToGetAddressFromPoint:)
												 name:kSTXGeoServicesNotification_AddressFromPoint_Error
											   object:self.mapView.geoServices];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didSolveRouteOK:)
												 name:kSTXGeoServicesNotification_FindRoute_OK
											   object:self.mapView.geoServices];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didFailToSolveRoute:)
												 name:kSTXGeoServicesNotification_FindRoute_Error
											   object:self.mapView.geoServices];
}

- (void)didTapStartPoint:(AGSPoint *)mapPoint
{
    NSOperation *op = [self.mapView.geoServices getAddressFromPoint:mapPoint];
    objc_setAssociatedObject(op, kSTXGetAddressReasonKey, kSTXGetAddressReasonRouteStart, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)didTapEndPoint:(AGSPoint *)mapPoint
{
    NSOperation *op = [self.mapView.geoServices getAddressFromPoint:mapPoint];
    objc_setAssociatedObject(op, kSTXGetAddressReasonKey, kSTXGetAddressReasonRouteEnd, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)didTapToReverseGeocode:(AGSPoint *)mapPoint
{
	NSOperation *op = [self.mapView.geoServices getAddressFromPoint:mapPoint];
    objc_setAssociatedObject(op, kSTXGetAddressReasonKey, kSTXGetAddressReasonReverseGeocodeForPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setRouteStartPoint:(AGSPoint *)routeStartPoint
{
    _routeStartPoint = routeStartPoint;
    if (_routeStartPoint)
    {
		self.currentState = STXSampleAppStateDirections;
        [self setToFromButton:self.routeStartButton selectedState:NO];
        if (![self doRouteIfPossible])
		{
			self.currentState = STXSampleAppStateDirections_WaitingForRouteEnd;
		}
    }
    [self setStartText];
}

- (void) setRouteEndPoint:(AGSPoint *)routeEndPoint
{
    _routeEndPoint = routeEndPoint;
    if (_routeEndPoint)
    {
		self.currentState = STXSampleAppStateDirections;
        [self setToFromButton:self.routeEndButton selectedState:NO];
        if (![self doRouteIfPossible])
		{
			self.currentState = STXSampleAppStateDirections_WaitingForRouteStart;
		}
	}
    [self setEndText];
}

- (void) setRouteStartAddress:(NSString *)routeStartAddress
{
    _routeStartAddress = routeStartAddress;
    [self setStartText];
}

- (void) setRouteEndAddress:(NSString *)routeEndAddress
{
    _routeEndAddress = routeEndAddress;
    [self setEndText];
}

- (BOOL) doRouteIfPossible
{
    if (self.routeStartPoint &&
        self.routeEndPoint)
    {
        NSLog(@"Start and end points set...");
        [self.mapView.geoServices getDirectionsFrom:self.routeStartPoint To:self.routeEndPoint];
        return YES;
    }
    return NO;
}

- (void) didSolveRouteOK:(NSNotification *)notification
{
	AGSRouteTaskResult *results = [notification.userInfo objectForKey:kSTXGeoServicesNotification_FindRoute_RouteTaskResultsKey];
	if (results)
	{
		self.routeResult = [results.routeResults objectAtIndex:0];
		[self.mapView.routeDisplayHelper showRouteResults:results];
	}
}

- (void) didFailToSolveRoute:(NSNotification *)notification
{
	NSError *error = [notification.userInfo objectForKey:kSTXGeoServicesNotification_ErrorKey];
	if (error)
	{
		NSLog(@"Failed to solve route: %@", error);
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not calculate route"
														message:[error.userInfo objectForKey:@"NSLocalizedFailureReason"]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

- (void) routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didSolveWithResult:(AGSRouteTaskResult *)routeTaskResult
{
    self.routeResult = routeTaskResult;
}

- (void) setStartText
{
    NSString *latLongText = nil;
    if (self.routeStartPoint)
    {
        AGSPoint *wgs84Pt = [STXHelper getWGS84PointFromPoint:self.routeStartPoint];
        latLongText = [NSString stringWithFormat:@"%.4f,%.4f", wgs84Pt.y, wgs84Pt.x];
    }
    NSString *address = self.routeStartAddress;
    if (latLongText && address)
    {
        self.routeStartLabel.text = [NSString stringWithFormat:@"%@ (%@)", address, latLongText];
    }
    else if (latLongText)
    {
        self.routeStartLabel.text = latLongText;
    }
    else {
        self.routeStartLabel.text = address;
    }
}

- (void) setEndText
{
    NSString *latLongText = nil;
    if (self.routeEndPoint)
    {
        AGSPoint *wgs84Pt = [STXHelper getWGS84PointFromPoint:self.routeEndPoint];
        latLongText = [NSString stringWithFormat:@"%.4f,%.4f", wgs84Pt.y, wgs84Pt.x];
    }
    NSString *address = self.routeEndAddress;
    if (latLongText && address)
    {
        self.routeEndLabel.text = [NSString stringWithFormat:@"%@ (%@)", address, latLongText];
    }
    else if (latLongText)
    {
        self.routeEndLabel.text = latLongText;
    }
    else {
        self.routeEndLabel.text = address;
    }
}

- (IBAction)clearRoute:(id)sender {
    if (self.routeResult)
    {
        self.routeResult = nil;
        [self.mapView.routeDisplayHelper clearRouteDisplay];
		self.routeStartAddress = nil;
		self.routeEndAddress = nil;
        self.routeStartPoint = nil;
        self.routeEndPoint = nil;
        self.currentState = STXSampleAppStateDirections_WaitingForRouteStart;
    }
}

- (void)setToFromButton:(UIButton *)bi selectedState:(BOOL)selected
{
    // Clear the other button regardless of the new state for this one.
    UIButton *otherBi = (bi == self.routeStartButton)?self.routeEndButton:self.routeStartButton;
	//    otherBi.tintColor = nil;
    otherBi.selected = NO;
	//    UIColor *tintColor = (bi == self.routeStartButton)?[UIColor greenColor]:[UIColor redColor];
    objc_setAssociatedObject(otherBi, kSTXApplicationLocFromState, [NSNumber numberWithBool:NO], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // Set the new state for this one, and set our app state too.
    NSLog(@"Selected: %@", selected?@"YES":@"NO");
    bi.selected = selected;
    if (selected)
    {
		//        bi.tintColor = [UIColor colorWithWhite:0.6 alpha:1];
		//        bi.tintColor = tintColor;
        self.currentState = (bi == self.routeStartButton)?STXSampleAppStateDirections_WaitingForRouteStart:STXSampleAppStateDirections_WaitingForRouteEnd;
    }
    else
    {
		//        bi.tintColor = nil;
        self.currentState = STXSampleAppStateDirections;
    }
    objc_setAssociatedObject(bi, kSTXApplicationLocFromState, [NSNumber numberWithBool:selected], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IBAction)toFromTapped:(id)sender {
    BOOL selected = [(NSNumber *)objc_getAssociatedObject(sender, kSTXApplicationLocFromState) boolValue];
    [self setToFromButton:sender selectedState:!selected];
}


#pragma mark - Find Address

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	NSString *searchString = searchBar.text;
	NSLog(@"Searching for: %@", searchString);
    AGSPolygon *v = self.mapView.visibleArea;
    AGSEnvelope *env = v.envelope;
	[self.mapView.geoServices getPointFromAddress:searchString withinEnvelope:env];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void) gotCandidatesForAddress:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSOperation *op = [userInfo objectForKey:kSTXGeoServicesNotification_WorkerOperationKey];
	
    if (op)
    {
        // First, let's remove all the old items (if any)
        [self.mapView removeGraphicsMatchingCriteria:^BOOL(AGSGraphic *g) {
            if ([g.attributes objectForKey:@"Source"])
            {
                NSLog(@"Removing graphic!");
                return YES;
            }
            return NO;
        }];
        
        NSArray *candidates = [userInfo objectForKey:kSTXGeoServicesNotification_PointsFromAddress_LocationCandidatesKey];
        if (candidates.count > 0)
        {
            NSArray *sortedCandidates = [candidates sortedArrayUsingComparator:^(id obj1, id obj2) {
                AGSAddressCandidate *c1 = obj1;
                AGSAddressCandidate *c2 = obj2;
                return (c1.score==c2.score)?NSOrderedSame:(c1.score > c2.score)?NSOrderedAscending:NSOrderedDescending;
            }];
            double maxScore = ((AGSAddressCandidate *)[sortedCandidates objectAtIndex:0]).score;
            AGSMutableEnvelope *totalEnv = nil;
            NSUInteger count = 0;
            for (AGSAddressCandidate *c in sortedCandidates) {
                if (c.score == maxScore)
                {
                    count++;
                    NSLog(@"Address found: %@", c.attributes);
                    AGSPoint *p = [STXHelper getWebMercatorAuxSpherePointFromPoint:c.location];
                    AGSGraphic *g = [self.mapView addPoint:p];
                    [g.attributes setObject:@"Geocoded" forKey:@"Source"];
                    if (!totalEnv)
                    {
                        totalEnv = [AGSMutableEnvelope envelopeWithXmin:p.x-1 ymin:p.y-1 xmax:p.x+1 ymax:p.y+1 spatialReference:p.spatialReference];
                    }
                    else
                    {
                        [totalEnv unionWithPoint:p];
                    }
                }
                else
                {
                    break;
                }
            }
            if (count == 1)
            {
                [self.mapView centerAtPoint:[totalEnv center] withScaleLevel:17];
            }
            else if (totalEnv)
            {
                [self.mapView zoomToEnvelope:totalEnv animated:YES];
            }
        }
    }
}

#pragma mark - Geolocation

- (IBAction)findMe:(id)sender {
	[self.mapView centerAtMyLocationWithScaleLevel:self.findScale];
}

- (IBAction)findScaleChanged:(id)sender {
    UISlider *slider = sender;
    self.findScale = (NSUInteger)roundf(slider.value);
}

- (IBAction)zoomToLevel:(id)sender {
    [self.mapView zoomToLevel:self.findScale];
}

- (void)setFindScale:(NSUInteger)findScale
{
    _findScale = findScale;
    self.findScaleLabel.text = [NSString stringWithFormat:@"%d", _findScale];
}
@end