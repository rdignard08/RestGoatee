//
//  RDDViewController.m
//  RestGoateeExample
//
//  Created by Ryan Dignard on 10/1/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

#import "RDDViewController.h"
#import "RDDTableCell.h"

@interface RDDViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITextField* textField;
@property (nonatomic, weak) IBOutlet UITableView* tableView;

@property (nonatomic, strong) NSArray* albums;

@end

@implementation RDDViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RDDTableCell" bundle:nil] forCellReuseIdentifier:@"Cell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAlbums:) name:[NSString stringWithFormat:@"%s", sel_getName(@selector(getItunesArtist:))] object:nil];
}

- (void) newAlbums:(NSNotification*)notification {
    self.albums = notification.object;
    [self.tableView reloadData];
}

- (BOOL) textFieldShouldReturn:(UITextField*)textField {
    [[RDDAPIClient sharedManager] getItunesArtist:textField.text];
    return YES;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albums.count;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    RDDTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    RDDItunesEntry* entry = self.albums[indexPath.row];
    
    cell.songName.text = entry.trackName;
    cell.bandName.text = entry.artistName;
    
    cell.releaseDate.text = [entry.releaseDate description];
    
    return cell;
}

@end