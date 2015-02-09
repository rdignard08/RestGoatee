/* Copyright (c) 2/5/15, Ryan Dignard
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

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
    
    [[RDDAPIClient manager] getStationsWithCompletion:nil];
}

- (void) newAlbums:(NSNotification*)notification {
    self.albums = !notification.object || [notification.object isKindOfClass:[NSArray class]] ? notification.object : @[ notification.object ];
    [self.tableView reloadData];
}

- (BOOL) textFieldShouldReturn:(UITextField*)textField {
    [[RDDAPIClient sharedManager] getItunesArtist:textField.text];
    return YES;
}

- (NSInteger) numberOfSectionsInTableView:(__unused UITableView*)tableView {
    return 1;
}

- (NSInteger) tableView:(__unused UITableView*)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return (NSInteger)self.albums.count;
}

- (CGFloat) tableView:(__unused UITableView*)tableView heightForRowAtIndexPath:(__unused NSIndexPath*)indexPath {
    return 44.0f;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    RDDTableCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    RDDItunesEntry* entry = self.albums[(NSUInteger)indexPath.row];
    
    cell.songName.text = entry.trackName;
    cell.bandName.text = entry.artistName;
    
    cell.releaseDate.text = [entry.releaseDate description];
    
    return cell;
}

@end
