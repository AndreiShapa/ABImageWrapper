//
//  CollectionController.m
//  ImageWrapperDemo
//
//  Created by Alexandr Barenboim on 03.08.13.
//  Copyright (c) 2013 Alexandr Barenboym. All rights reserved.
//

#import "CollectionController.h"
#import "Cell.h"
#import "DetailedController.h"
#import "ABImageWrapper.h"
#import "DataModel.h"

UIViewController* getViewControllerWithID(NSString* controller_id)
{
    UIStoryboard* mainStoryboard;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad"
                                                   bundle: nil];
    }
    else
    {
        mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone"
                                                   bundle: nil];
    }
    
    UIViewController* controller = [mainStoryboard instantiateViewControllerWithIdentifier:controller_id];
    
    return controller;
}

@interface CollectionController ()
{
    NSMutableArray* data_source_images;
}

@end

@implementation CollectionController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.collection registerClass:[Cell class] forCellWithReuseIdentifier:@"cell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self clearVisibleCells];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collection reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)clearVisibleCells
{
    for (Cell* cell in self.collection.visibleCells) {
        [cell setImage:Nil];
    }
}

#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return 50;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* identifier = @"cell";
    Cell *cell = [cv dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    NSString* key = keyForIndexPath(indexPath);
    
    NSMutableDictionary* data = dataModel();
    
    ABImageWrapper* wrapper = [data valueForKey:key];
    
    [cell setImage:[wrapper mediumSize]];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* key = keyForIndexPath(indexPath);
    NSMutableDictionary* data = dataModel();
    ABImageWrapper* wrapper = [data valueForKey:key];
    
    if (wrapper) {
        DetailedController* controller = (DetailedController*)getViewControllerWithID(@"detailed");
        [self.navigationController pushViewController:controller animated:YES];
        [controller setImage:[wrapper fullSized] indexPath:indexPath];
        
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    else
    {
        UIActionSheet* popupQuery = [[UIActionSheet alloc] initWithTitle:Nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:Nil otherButtonTitles:@"Camera", @"Photo Library", nil];
        
        [popupQuery showInView:self.view];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [((Cell*)cell) setImage:Nil];
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(60, 60);
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 20, 10, 20);
}

#pragma mark - # UIImagePicker Controller delegate
- (void) imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
	// Access the uncropped image from info dictionary
    UIImage* image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    ABImageWrapper* wrapper = [ABImageWrapper createWithUIImage:image];
    
    NSIndexPath* path = [[self.collection indexPathsForSelectedItems] lastObject];
    
    NSString* key = keyForIndexPath(path);
    NSMutableDictionary* data = dataModel();
    [data setValue:wrapper forKey:key];
    
    [self stopUIImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self stopUIImagePicker];
}

- (void)stopUIImagePicker
{
    NSIndexPath* path = [[self.collection indexPathsForSelectedItems] lastObject];
    [self.collection deselectItemAtIndexPath:path animated:YES];
    
    //Take image picker off the screen (required)
	[self dismissViewControllerAnimated:YES completion:^(void){}];
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath* path;
    
    switch (buttonIndex) {
        case 0:
            [self presentImagePicker:YES];
            break;
        case 1:
            [self presentImagePicker:NO];
            break;
        case 2:
            path = [[self.collection indexPathsForSelectedItems] lastObject];
            [self.collection deselectItemAtIndexPath:path animated:YES];
        default:
            break;
    }
}

- (void)presentImagePicker:(BOOL)camera
{
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    
    if (camera) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        }
    }
    
    // Delegate is self
	imagePicker.delegate = self;
    
    // Allow editing of image ?
    //	imagePicker.allowsEditing = YES;
    
    // Show image picker
	[self presentViewController:imagePicker animated:YES completion:^(void){}];
}

@end
