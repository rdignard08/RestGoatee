//
//  RDDTableCellTableViewCell.h
//  RestGoateeExample
//
//  Created by Ryan Dignard on 10/1/14.
//  Copyright (c) 2014 Ryan Dignard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RDDTableCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel* songName;
@property (nonatomic, weak) IBOutlet UILabel* bandName;
@property (nonatomic, weak) IBOutlet UILabel* releaseDate;

@end
