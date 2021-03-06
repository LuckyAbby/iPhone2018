//
//  TimiTableViewController.m
//  Timi
//
//
//  Created by abby on 18/12/11.
//

#import "TimiTableViewController.h"
#import "TimiTableViewCell.h"
#import "AddNoteViewController.h"
#import "TimiDelegate.h"


@interface TimiTableViewController  () <TimiTableViewCellDelegate>

@property (nonatomic, strong) NSMutableArray *itemArr;
@property (nonatomic, assign) double totalIncome;
@property (nonatomic, assign) double totalOutcome;
@property (weak, nonatomic)  UILabel *totalIncomeLabel;
@property (weak, nonatomic)  UILabel *totalOutcomeLabel;
@property (nonatomic, copy) NSArray *incomeItemNameArr;


@property (nonatomic, assign) BOOL isEditingItem;
@property (nonatomic, assign) NSInteger editItemNum;
@property (nonatomic, strong) NSDate *editItemTimeStamp;

@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) NSMutableArray *headerIndexArr;

@end

@implementation TimiTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self headerViewInit];
    [self refreshData];
    


}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itemArr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self selectionOrder];
    
    NSManagedObject *object = self.itemArr[indexPath.row];
    NSString *content = [object valueForKey:@"content"];
    NSNumber *cost = [object valueForKey:@"cost"];
    NSNumber *isOutcome = [object valueForKey:@"isOutcome"];
    NSString *logo = [object valueForKey:@"logo"];
    NSDate *date = [object valueForKey:@"timeStamp"];
    
    TimiItem *item = [[TimiItem alloc] initWithContent:content itemCost:cost.doubleValue logoStr:logo insertTime:date contentType:isOutcome.boolValue];
    
    NSString *identifier = @"";
    if (item.isOutcome) {
        identifier = @"RightCell";
    } else {
        identifier = @"LeftCell";
    }

    TimiTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell.delegate) {
        cell.delegate = self;
    }
    
    [self markHeaderItem];
    
    for (NSNumber *num in self.headerIndexArr) {
        if (indexPath.row == num.integerValue) {
            item.isHeader = YES;
        }
    }
    
//    [self calculateTotalValue:item]; //不能每次加载一个就加，因为有复用。。
    [cell configureCell:item];
    
    return cell;
}



#pragma mark - headerView - Methods

- (void)headerViewInit
{
    UIView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"HeaderView" owner:nil options:nil] firstObject];
    self.tableView.tableHeaderView = headerView;
    self.totalIncomeLabel = [headerView viewWithTag:2];
    self.totalOutcomeLabel = [headerView viewWithTag:3];
    UIButton *addBtn = [headerView viewWithTag:1];
    [addBtn addTarget:self action:@selector(clickAddBtn) forControlEvents:UIControlEventTouchUpInside];
}

- (void)clickAddBtn
{
    CATransition* transition = [CATransition animation];
    transition.type = @"suckEffect";//可更改为其他方式
    transition.subtype = kCATransitionFromBottom;//可更改为其他方式
    transition.duration=0.3;
    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    
    AddNoteViewController *con = [[AddNoteViewController alloc] init];
    con.delegate = self;
    con.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:con animated:YES];

}

//从效率来讲应该是定义为总收入总支出两个属性，每次修改的时候直接在原有基础上修改就好
//但目前 重新算一遍就好了
- (void)calculateTotalValue
{
    self.totalIncome = 0;
    self.totalOutcome = 0;
    for (NSManagedObject *object in self.itemArr) {
        NSNumber *isOutCome = [object valueForKey:@"isOutcome"];
        NSNumber *cost = [object valueForKey:@"cost"];
        if (isOutCome.boolValue) {
            self.totalOutcome += cost.doubleValue;
        } else {
            self.totalIncome += cost.doubleValue;
        }
    }
    
    self.totalIncomeLabel.text = [NSString stringWithFormat:@"%.2f",self.totalIncome];
    self.totalOutcomeLabel.text = [NSString stringWithFormat:@"%.2f",self.totalOutcome];
}

#pragma mark TimiTableViewCellDelegate
//点击edit按钮
- (void)timiCellClickEditBtn:(TimiTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    TimiItem *item = self.itemArr[indexPath.row];
    
    AddNoteViewController *addCon = [[AddNoteViewController alloc] init];
    addCon.delegate = self;
    addCon.view.backgroundColor = [UIColor whiteColor];
    addCon.keyboardView.contentLabel.text = item.content;
    addCon.keyboardView.contentCostLabel.text = [NSString stringWithFormat:@"$%.2f",item.cost];
    UIImage *image = [UIImage imageNamed:item.logo];
    [image setAccessibilityIdentifier:item.logo];
    addCon.keyboardView.contentLogo.image = image;
    
    self.isEditingItem = YES; //因为edit过去的话，返回的时候，就是替换掉这个就好了,所以记录当前edit的item的位置，然后传回来的时候，更新相应位置上的item就好
    self.editItemNum = indexPath.row;
    self.editItemTimeStamp = item.timeStamp;
    
    CATransition* transition = [CATransition animation];
    transition.type = @"pageCurl";//可更改为其他方式
    transition.subtype = kCATransitionFromBottom;//可更改为其他方式
    transition.duration=0.5;
    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    
    
    [self.navigationController pushViewController:addCon animated:YES];
}

//点击删除按钮
- (void)timiCellClickDeleteBtn:(TimiTableViewCell *)cell
{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"提示" message:@"确定要删除？" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        [self.managedObjectContext deleteObject:self.itemArr[indexPath.row]];
        [self.managedObjectContext save:nil];
        [self refreshData];
    }]; //UIAlertAction相当于一种封装了触发方法的选项按钮
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }]; //UIAlertAction相当于一种封装了触发方法的选项按钮
    [alertView addAction:action];
    [alertView addAction:action2];
    //    [self.navigationController pushViewController:alertView animated:YES];
    [self presentViewController:alertView animated:YES completion:^{
        
    }];
}


#pragma mark - ItemCompleteDelegate
- (void)finisCompletingItem:(NSString *)contentPic contentStr:(NSString *)contentStr totalCost:(double)cost timeStamp:(NSDate *)date
{
    //得判断是新创建的 还是edit返回来的（替换掉原来的就好）
    NSManagedObject *entityDes = [NSEntityDescription insertNewObjectForEntityForName:@"Item" inManagedObjectContext:self.managedObjectContext];
    NSNumber *isOutcome = [NSNumber numberWithBool:[self judgeItemIsOutcome:contentStr]];
    NSNumber *costNum = [NSNumber numberWithDouble:cost];
    [entityDes setValue:contentStr forKey:@"content"];
    [entityDes setValue:contentPic forKey:@"logo"];
    [entityDes setValue:isOutcome forKey:@"isOutcome"];
    [entityDes setValue:costNum forKey:@"cost"];
    
    if (self.isEditingItem) {
        [self.managedObjectContext deleteObject:self.itemArr[self.editItemNum]];
        [entityDes setValue:self.editItemTimeStamp forKey:@"timeStamp"];
        self.isEditingItem = false;
    } else {
        [entityDes setValue:date forKey:@"timeStamp"];
    }
    [self.managedObjectContext save:nil];
    [self refreshData];
}


#pragma mark - comman Methods
//判断支出还是收入
- (BOOL)judgeItemIsOutcome:(NSString *)contentStr
{
    for (NSString *str in self.incomeItemNameArr) {
        if ([contentStr isEqualToString:str]) {
            return false;
        }
    }
    return true;
}
//更新数据
- (void)refreshData
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
    NSArray *tempArr = [self.managedObjectContext executeFetchRequest:request error:nil];
    [self.itemArr removeAllObjects];
    self.itemArr = [NSMutableArray arrayWithArray:tempArr];
    [self calculateTotalValue];
    self.currentDate = nil;
    [self.tableView reloadData];
}
//选择排序
- (void)selectionOrder
{
    //每次出来都按时间排个序  因为经常要调用 是几乎排好的，所以选择排序
    for (int i = 1; i < self.itemArr.count; i++) {
        NSDate *idate = [self.itemArr[i] valueForKey:@"timeStamp"];
        NSManagedObject *iobject = self.itemArr[i];
        int j = 0;
        for (j = i; j > 0; j--) {
            NSDate *jdate = [self.itemArr[j-1] valueForKey:@"timeStamp"];
            NSDate *resultDate = [idate earlierDate:jdate];
            if ([resultDate isEqualToDate:idate]) {
                break;
            }
            self.itemArr[j] = self.itemArr[j-1];
        }
        self.itemArr[j] = iobject;
    }
}

//把是header的都标记出来并把index存到数组headerIndexArr里
- (void)markHeaderItem
{
    self.currentDate = nil;
    [self.headerIndexArr removeAllObjects];
    for (int i = 0; i < self.itemArr.count; i++) {
        NSManagedObject *object = self.itemArr[i];
        NSDate *date = [object valueForKey:@"timeStamp"];
        if ([self judgeIsHeader:date]) {
            //把是header的序号都标记好 收集起来
            [self.headerIndexArr addObject:[NSNumber numberWithInt:i]];
        }
    }
}

- (BOOL)judgeIsHeader:(NSDate *)date
{
//    判断是否新的一组 是的话 显示timeStamp和dotView 否则隐藏
    if (![self isSameDay:date withDate2:self.currentDate]) {
        self.currentDate = date;
        return true;
    }
    return false;
}

    
- (BOOL)isSameDay:(NSDate *)date1 withDate2:(NSDate *)date2
{
        long time1 = [date1 timeIntervalSince1970]/(24*3600);
        long time2 = [date2 timeIntervalSince1970]/(24*3600);
        long result = time1-time2;
        if (result == 0) {
            return TRUE;
        } else {
            return FALSE;
        }
}


#pragma mark 懒加载
- (NSMutableArray *)itemArr
{
    if (!_itemArr)
    {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
        NSArray *tempArr = [self.managedObjectContext executeFetchRequest:request error:nil];
        _itemArr = [NSMutableArray arrayWithArray:tempArr];
    }
    return _itemArr;
}


- (NSArray *)incomeItemNameArr
{
    if (!_incomeItemNameArr) {
        _incomeItemNameArr = @[@"工资", @"收入", @"工作"];
    }
    return _incomeItemNameArr;
}

- (NSDate *)editItemTimeStamp
{
    if (!_editItemTimeStamp) {
        _editItemTimeStamp = [NSDate date];
    }
    return _editItemTimeStamp;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    }
    return _managedObjectContext;
}

- (NSMutableArray *)headerIndexArr
{
    if (!_headerIndexArr) {
        _headerIndexArr = [NSMutableArray array];
    }
    return _headerIndexArr;
}

@end
